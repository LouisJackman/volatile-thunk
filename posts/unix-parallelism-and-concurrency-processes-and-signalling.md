title: Unix Parallelism and Concurrency: Processes & Signalling
date: 2018-02-12 12:00
tags: unix, linux, rust
---
In this era of threads and asynchronous abstractions, applications and processes
have become almost synonymous. A process is widely seen as the operating
system's underlying representation of a whole running application. However, by
limiting ourselves to this model we cut outselves off from an elegant set of
tools for parallelism and concurrency.

In case you thought this blog's design looked prehistoric enough, it's starting
with a post about following concurrency patterns rooted in the era in which the
mouse was a keen invention.

***

The key construct behind process-based Unix concurrency is the
[fork](https://linux.die.net/man/2/fork) system call. It's practically a
paradox: one program calls it yet two programs finish calling it to move on.
This appears as quite the oddity to programmers of contemporary environments
like Java and the JavaScript; how can a mere function call violate the
fundamental laws of how a written program executes?

Most environments, despite having a set of rules its programmers can depend on,
have occasional strange artefacts on the surface that violate such rules and
are exposed by the underlying system.

A Java program holding a reference to an object ensures that
object remains alive, but the system exposes a different type of reference
tracking with the
[java.lang.ref.WeakReference](https://docs.oracle.com/javase/9/docs/api/java/lang/ref/WeakReference.html)
type insofar as allowing an object to be deleted while the programmer is still
holding onto it. Likewise, storing a string literal into a object will never
block execution in JavaScript, but there's an exception that exposes the
underlying browser environment:
[window.location](https://developer.mozilla.org/en-US/docs/Web/API/Window/location).
Assigning a string to that cancels the current flow of execution by redirecting
the page, halting the current JavaScript environment and throwing it away.

In C or Rust, or even other higher level language like Ruby or Python, the
environment is not a language-specific world unto itself like Java or a web
browser; it is instead our underlying operating system. To understand our
underlying operating system, we can look at specifications such as
[POSIX](https://en.wikipedia.org/wiki/POSIX) which most Unix variants will
mostly align with.

Apart from your operating system, language runtimes such as those in Ruby and
Python provide extra gizmos provided like stack-unwinding, garbage collection
and some introspection capabilities. System calls from these languages, like the
previous examples, provide capabilities that can step outside of the normal
rules of the language you are using. Unix doesn't care about the Rust `drop`
method that your language runtime makes ["guarantees" about running at the end
of the scope](https://doc.rust-lang.org/stable/reference/destructors.html); if
you `exec`, the whole process' runtime image is being swapped out and execution
is jumping. Those method calls will be deep sixed.

For the demonstrations in this article, Rust is used. After [installing
it](https://www.rust-lang.org/tools/install), set up a new project by changing
into a new project directory and running `cargo init --bin`. Three packages
outside of its standard libraries are used: `num_cpus` for counting the number
of processors on the machine, `anyhow` to simplify error-handling, and `nix` to
give expanded access to Unix's concurrency APIs. Add all of these with `cargo
add anyhow nix num_cpus`. Replace the generated `src/main.rs` file with the
content of each example before running them, which can be done with `cargo run`.

Invoking the `fork` system call in Rust is as follows:

```rust
use {
    anyhow::Result,
    nix::unistd::{
        fork,
        ForkResult::{Child, Parent},
    },
};

fn main() -> Result<()> {
    match unsafe { fork() }? {
        Child => println!("In child process"),
        Parent { child } => println!("In parent process; this child is {child}"),
    }
    println!("Finished a process");
    Ok(())
}
```

Rust supports returning `Result` types from the main function. In this case,
it'll automatically report erroneous reports as a message for the user. This is
used consistently across the examples when errors are possible. As `fork`
violates the expectations of most languages, Rust expects calls to it to be
wrapped in `unsafe` blocks. `?` is used to return errors back up to main; the
`?` notation is used throughout the examples to return early from functions in
the case of errors. `()` is the "unit type" which essentially means "nothing".
Put together, `Ok(())` means "a successful operation that yielded nothing
useful".

This program demonstrates that oxymoron of one program entering `fork` and two
leaving it; how else could _both_ branches be run in a single `if`? This allows
for a form of concurrency and parallelism:

```shell
$ cargo run
In parent process; this child is 906
Finished a process
In child process
Finished a process
```

Running operations side-by-side is hardly an elusive trick. Anyone spinning up a
thread in Java or interleaving two `setTimeout`s in JavaScript could replicate
something similar. Unlike the latter, however, the application can still
continue while one of the hangs for ten seconds:

```rust
use {
    anyhow::Result,
    nix::unistd::{
        fork,
        ForkResult::{Child, Parent},
    },
    std::{thread::sleep, time::Duration},
};

fn main() -> Result<()> {
    match unsafe { fork() }? {
        Child => sleep(Duration::from_secs(10)),
        Parent { .. } => println!("Finished"),
    }
    Ok(())
}
```

```shell
$ cargo run
Finished
```

These clearly aren't events being dispatched into an event loop behind the
scenes, otherwise the ten-second hang would temporarily block the event loop,
stopping the second event `println!("finished")` from running. Single events
blocking the entire event loop and grinding large applications to a halt [is not
a theoretical
problem](https://www.owasp.org/index.php/Regular_expression_Denial_of_Service_-_ReDoS).

Threads sidestep this problem by utilising the operating system's _scheduler_
which slices up time on the computer between competing tasks to avoid any
one of them starving the whole system of resources, but they come with their
own arsenel of footguns in many shapes and sizes:

```rust
use {
    num_cpus,
    std::{
        thread::{sleep, spawn, JoinHandle},
        time::Duration,
    },
};

struct UserCounter {
    count: usize,
}

impl UserCounter {
    pub fn new() -> Self {
        Self { count: 0 }
    }

    pub fn increment(&mut self) {
        let count = self.count;
        println!("User {count} visited");
        self.count = count + 1;
    }
}

fn main() {
    let mut counter = UserCounter::new();
    let counter_ptr = ((&mut counter) as *mut UserCounter) as usize;

    let handle_requests = move || loop {
        sleep(Duration::from_millis(300));
        let p = counter_ptr as *mut UserCounter;
        unsafe { &mut *p }.increment();
    };

    let threads: Vec<JoinHandle<()>> = (1..num_cpus::get())
        .map(|_| spawn(handle_requests))
        .collect();
    for thread in threads {
        thread.join().unwrap();
    }
}
```

A counter struct is created, but it's incrementing of said counter is split
across multiple operations which are then interleaved across many threads.
This is where disaster strikes. Rust advertises itself as having "fearless
concurrency", and this is demonstrated here: doing it the obvious way -- passing
a reference to `counter` into the thread's closure -- causes Rust to reject the
code. It knows that the counter cannot safely be modified from multiple threads.
To demonstrate this failure at runtime, we bypass Rust's safety paniopticon by
smuggling a reference to the counter into a simple numeric type (`usize`) and
then materialising it back into a pointer inside the thread. Dereferencing raw
pointers conjured out of arbitary numbers is not memory-safe, so we pull out
`unsafe` again.

The bug Rust tried to prevent strikes; the loading and incrementing is
interleaved with other concurrent threads, causing the counter to be wrong most
of the time.

```shell
$ cargo run
User 0 visited
User 0 visited
User 1 visited
User 2 visited
User 0 visited
User 1 visited
User 0 visited
User 0 visited
User 1 visited
User 2 visited
User 3 visited
User 4 visited
User 5 visited
User 6 visited
User 7 visited
User 8 visited
User 9 visited
User 10 visited
User 8 visited
User 8 visited
User 9 visited
User 8 visited
```

We must remember quite a few rules to avoid shooting ourselves in the foot in
multithreaded systems.
[Just a few.](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html#jls-17.4.5)

Between dealing with data races, deadlocks, stale reads, and other threading
esoteria, programming with threads is playing Russian Roulette with a fully
loaded uzi. An uzi that jams a lot too, as adding too many _critical regions_ to
synchronise threaded code bottlenecks your otherwise concurrent program into
single-threaded hotspots that can end up throttling your application's
performance.

Have you managed to get the locking fine-grained enough to get good performance
while avoiding those pitfalls? Well, hopefully you're not building any more
abstractions on top of it, as
[locks do not compose](https://www.youtube.com/watch?v=dGVqrGmwOAw).

Operating system processes are bulky and cannot be spun up as fast as threads,
but are more isolated from one another. They have their own memory space,
meaning one buggy process can't corrupt the in-memory data of another. Unlike
threads, misbehaving processes can actually be killed without causing
[strange, hard to trace bugs in the underlying system](https://docs.oracle.com/javase/8/docs/technotes/guides/concurrency/threadPrimitiveDeprecation.html).

Processes also encourage communication via message-passing mechanisms like
signalling, domain sockets, and networking connections. It turns out that these
solutions are easier to scale across multiple physical machines than shared
memory communication, as
[others also discovered quite a long time ago](https://www.erlang.org/).

Signalling is the easiest way to get your feet wet with Unix IPC, _Inter-Process
Communication_:

```rust
use {
    anyhow::Result,
    nix::{
        sys::{
            signal::{kill, SigSet, Signal, SIGCONT},
            wait::waitpid,
        },
        unistd::{fork, ForkResult::Parent, Pid},
    },
    std::{process::exit, thread::sleep, time::Duration},
};

fn sigwait(signals: &[Signal]) -> Result<Signal> {
    let mut set = SigSet::empty();
    for signal in signals {
        set.add(*signal);
    }
    set.thread_block()?;
    let signal = set.wait()?;
    Ok(signal)
}

const fn new_operation<'a>(name: &'a str, wait_secs: u64) -> impl Fn() -> Result<()> + 'a {
    move || {
        println!("Starting {name} operation...");
        sleep(Duration::from_secs(wait_secs));

        kill(Pid::parent(), SIGCONT)?;
        sigwait(&[SIGCONT])?;

        println!("{name} operation complete.");
        Ok(())
    }
}

fn fork_new_operation(name: &str, wait_secs: u64) -> Result<Pid> {
    if let Parent { child } = unsafe { fork() }? {
        Ok(child)
    } else {
        let op = new_operation(name, wait_secs);
        op().unwrap();
        exit(0)
    }
}

fn start_children() -> Result<Vec<Pid>> {
    let child_1 = fork_new_operation("very expensive", 5)?;
    let child_2 = fork_new_operation("slightly expensive", 2)?;
    Ok(vec![child_1, child_2])
}

fn wait_for_all(children: &Vec<Pid>) -> Result<()> {
    for _ in children {
        sigwait(&[SIGCONT])?;
    }
    Ok(())
}

fn display_in_order(children: &Vec<Pid>) -> Result<()> {
    for &child in children {
        kill(child, Some(SIGCONT))?;
        waitpid(child, None)?;
    }
    Ok(())
}

fn main() -> Result<()> {
    let children = start_children()?;
    println!("All children started.");
    wait_for_all(&children)?;
    println!(
        "All children finished main tasks; asking them to display results in \
        order."
    );
    display_in_order(&children)?;
    Ok(())
}
```

This is a more complex example, so let's go through each component
piece-by-piece.

Firstly, we teach the program how to wait for a signal. It requires a few steps.
As it's done multiple times, the steps are encapsulated into a function called
`sigwait`. It creates a "signal set", adds the signals we wish to wait for,
tells the OS to block the current thread on the signal (a neccessity for
multithreaded code), and finally waits for a matching signal to come in.

Secondly, we have some operations that take time. Rather than duplicating them,
we have a function that returns new operation functions with the name and
time-taken provided. Being a systems language without a garbage collector,
Rust's concerns must be allayed: `'a` is a lifetime specified on `new_operation`.
It asserts to Rust that the name of the operation we pass in will not outlive
the returned function, as that function prints it out as it runs. After waiting
and displaying a message, it waits for the parent process to sent it a
"continuation" signal to carry on and finish.

Finally, the parent spins off two operations with different timeouts. Each child
sends a `SIGCONT` continuation signal to the parent. When the parent gets as
many of them as child processes, it knows they're both complete. It then sends
back `SIGCONT` in a specific order, meaning each process displays their final
message in an order coordinated by the parent.

Running this yields:

```shell
$ cargo run
Starting very expensive operation...
All children started.
Starting slightly expensive operation...
All children finished main tasks; asking them to display results in order.
very expensive operation complete.
slightly expensive operation complete.
```

The slightly expensive operation, despite being quicker, displays its
output after the longer running one. Both of them ran at the same time; it
waited for 5 seconds, not 2. To recap, combining `fork` with Unix process
signalling, the following was organised:

* Multiple tasks are forked in seperate processes. This not only allows IO
  interleaving like event systems, but also utilisation of multiple processor
  cores if we assumed the mock `sleep`s are actually computationally expensive
  operations.
* The parent process waits for a signal, specifically `SIGCONT`, to indicate a
  child process finished its main task. It waits for the same amount of signals
  as child processes. This means it does not move on until they all declare
  having finished.
* It iterates over the processes in the order they were defined, sends a
  message to each to display their results, and waits for them to complete.

The whole process not only parallelises the compution, but it linearises the
results. Notice the lack of locks, shared queues, and polling.

Running `man 7 signal` on a Unix device tells us what signals exist. Choosing
`SIGCONT` was an arbritary decision, as most of the signals here could have been
used. `SIGCONT` just so happens to best describe what it was doing: continuing
after the tasks had finished waiting for something else.

This relevant section of Linux's manpage for `signal` is illustrative:

```
Signal      Standard   Action   Comment
────────────────────────────────────────────────────────────────────────
SIGABRT      P1990      Core    Abort signal from abort(3)
SIGALRM      P1990      Term    Timer signal from alarm(2)
SIGBUS       P2001      Core    Bus error (bad memory access)
SIGCHLD      P1990      Ign     Child stopped or terminated
SIGCLD         -        Ign     A synonym for SIGCHLD
SIGCONT      P1990      Cont    Continue if stopped
SIGEMT         -        Term    Emulator trap
SIGFPE       P1990      Core    Floating-point exception
SIGHUP       P1990      Term    Hangup detected on controlling terminal
                                or death of controlling process
SIGILL       P1990      Core    Illegal Instruction
SIGINFO        -                A synonym for SIGPWR
SIGINT       P1990      Term    Interrupt from keyboard
SIGIO          -        Term    I/O now possible (4.2BSD)
SIGIOT         -        Core    IOT trap. A synonym for SIGABRT
SIGKILL      P1990      Term    Kill signal
SIGLOST        -        Term    File lock lost (unused)
SIGPIPE      P1990      Term    Broken pipe: write to pipe with no
                                readers; see pipe(7)
SIGPOLL      P2001      Term    Pollable event (Sys V);
                                synonym for SIGIO
SIGPROF      P2001      Term    Profiling timer expired
SIGPWR         -        Term    Power failure (System V)
SIGQUIT      P1990      Core    Quit from keyboard
SIGSEGV      P1990      Core    Invalid memory reference
SIGSTKFLT      -        Term    Stack fault on coprocessor (unused)
SIGSTOP      P1990      Stop    Stop process
SIGTSTP      P1990      Stop    Stop typed at terminal
SIGSYS       P2001      Core    Bad system call (SVr4);
                                see also seccomp(2)
SIGTERM      P1990      Term    Termination signal
SIGTRAP      P2001      Core    Trace/breakpoint trap
SIGTTIN      P1990      Stop    Terminal input for background process
SIGTTOU      P1990      Stop    Terminal output for background process
SIGUNUSED      -        Core    Synonymous with SIGSYS
SIGURG       P2001      Ign     Urgent condition on socket (4.2BSD)
SIGUSR1      P1990      Term    User-defined signal 1
SIGUSR2      P1990      Term    User-defined signal 2
SIGVTALRM    P2001      Term    Virtual alarm clock (4.2BSD)
SIGXCPU      P2001      Core    CPU time limit exceeded (4.2BSD);
                                see setrlimit(2)

SIGXFSZ      P2001      Core    File size limit exceeded (4.2BSD);
                                see setrlimit(2)
SIGWINCH       -        Ign     Window resize signal (4.3BSD, Sun)

The signals SIGKILL and SIGSTOP cannot be caught, blocked, or ignored.

Up to and including Linux 2.2, the default behavior for SIGSYS, SIGXCPU, SIGXFSZ, and (on architectures other than SPARC and MIPS) SIGBUS was to terminate
the process (without a core dump).  (On some other UNIX systems the default action for SIGXCPU and SIGXFSZ is to terminate  the  process  without  a  core
dump.)  Linux 2.4 conforms to the POSIX.1-2001 requirements for these signals, terminating the process with a core dump.

SIGEMT  is  not  specified  in  POSIX.1-2001,  but nevertheless appears on most other UNIX systems, where its default action is typically to terminate the
process with a core dump.

SIGPWR (which is not specified in POSIX.1-2001) is typically ignored by default on those other UNIX systems where it appears.

SIGIO (which is not specified in POSIX.1-2001) is ignored by default on several other UNIX systems.
```

Some of those signals have special behaviour, like being impossible to handle
such as `SIGKILL`, or being handled by some language runtimes for us, like
Ruby and Python translating `SIGINT` into rescuable errors. `SIGUSR1` and
`SIGUSR2` are good for non-standard signals for application-specific events.

We might want to wait for a signal, but not if it takes too long:

```rust
use {
    anyhow::Result,
    nix::{
        sys::signal::{kill, SigSet, Signal, SIGALRM, SIGCHLD, SIGKILL},
        unistd::{
            alarm, fork,
            ForkResult::{Child, Parent},
            Pid,
        },
    },
    std::{process::exit, thread::sleep, time::Duration},
};

struct Alarm;

impl Alarm {
    fn set(seconds: u32) -> Self {
        alarm::set(seconds);
        Self
    }
}

impl Drop for Alarm {
    fn drop(&mut self) {
        alarm::cancel();
    }
}

fn run_slow_operation() {
    sleep(Duration::from_secs(10));
    println!("Finished slow operation");
}

fn sigwait(signals: &[Signal]) -> Result<Signal> {
    let mut set = SigSet::empty();
    for signal in signals {
        set.add(*signal);
    }
    set.thread_block()?;
    let signal = set.wait()?;
    Ok(signal)
}

fn wait_for(pid: Pid) -> Result<()> {
    let _alarm = Alarm::set(5);

    if sigwait(&[SIGCHLD, SIGALRM])? == SIGALRM {
        println!("Too late; killing child process");
        kill(pid, SIGKILL)?;
    } else {
        println!("Child process finished");
    }

    Ok(())
}

fn main() -> Result<()> {
    match unsafe { fork() }? {
        Child => {
            run_slow_operation();
            exit(0);
        }
        Parent { child } => wait_for(child)?,
    }
    Ok(())
}
```

```shell
$ cargo run
Too late; killing child process
```

`sigwait` was borrowed from the previous example. We take advantage of Rust's
destructors to allow creating an alarm that is guaranteed to be disarmed even if
an error occurs throughout its existence; this is done in Rust by implementing
[the Drop trait](https://doc.rust-lang.org/stable/reference/destructors.html).

Alarms allow timers to be interleaved with events. `SIGCHLD` is a signal for
when any child processes stop running; secondly, some signals like `SIGCHLD` do
nothing by default.

If we wanted, we could put all of our event handling logic directly in signal
handlers rather than waiting with `sigwait`. However, handling them inline like
that opens us up to the gnarly world of ["asynchronous signal-safe
behaviour"](https://man7.org/linux/man-pages/man7/signal-safety.7.html). It's
better to do the bare minimum in the handler, just dispatching an event that can
be handled by normal code in the usual execution flow. A lot of libraries will
dispatch signals as events via a wrapper to avoid this exact footgun.

Be careful of default signal behaviour. If your program is being run by a parent
process, it can pass down a non-default signalset for "masking". As we
demonstrated above, a process registers its interest in signals using the
mechanisms in our `sigwait` function. Underneath, this is using the POSIX notion
of ["signal
masking"](https://www.ibm.com/docs/en/i/7.1?topic=ssw_ibm_i_71/apis/users_96.html).
If a signal must be picked up by your program, even for just `sigwait`, add it
to the current process's signal mask to be sure. Remember that threads must also
be considered.

Signalling is one of the simplest forms of Unix IPC. It's enough to coordinate
processes, but does not allow sending messages with payloads. Domain sockets,
networking connections, and other IPC systems allow a programmer to go a lot
further.

***

If Unix IPC is such a powerful and battle-tested standard for parallelisation
and concurrency, why isn't it the primary port of call for solving such problems
today? Well, for starters it's slow and bulky even with modern optimisations
like copy-on-write for copying processes' memory spaces to forked children.
Although shared memory has problems, it is sometimes the best way of solving
certain problems and it's easier with threads. Event-driven systems avoid many
of the problems with threads and handle the majority of concurrency use cases in
modern webservices, so managing processes manually becomes unnecessary.

Many applications written in the likes of Node.js use processes just to utilize
as many processor cores as possible, but hide process management behind modules
like `cluster`. Processes are used to parallelise, but the concurrency is
handled by abstractions built atop an event loop. Using a process per request
would destroy performance as they are too coarse for that level of fine-grained
concurrency.  In fact, that's how web applications were handled many years ago
in CGI scripts.  There's a reason it isn't done that way anymore.

Despite these problems, Unix IPC mechanisms are sometimes still the best way of
tackling certain concurrency and parallelism problems, so it's worth keeping
those dusty old '70s techniques in the toolbox.
