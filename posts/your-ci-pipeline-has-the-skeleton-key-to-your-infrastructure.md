title: Your CI Pipeline has the Skeleton Key to your Infrastructure
date: 2018-11-25 12:00
tags: infrastructure, devops, cloud, security, sysadmin
---
Continuous integration is a must-have for technology companies these days.
Developers expect to be able to push code via git and have the resulting code
automatically built, tested, packaged up, and in the case of continuous
delivery, deployed. Even infrastructure changes are increasingly transcribed in
code using tools like Terraform and then planned and applied via CI.

If companies aren't careful, the result is just one part of their infrastructure
having the master key for the rest of it, becoming a lucrative target for
adversaries.

---

As companies seek to decentralise from monoliths towards microservices, however
effective that trend du jour actually is at improving scaling, the management
of infrastructure and deployments is centralised to counter the surge of
complexity caused by orchestrating many smaller services.

This can hardly be worse than developers deploying from their laptops, which
really doesn't scale as companies grow. The server can be more focussed than a
developer's laptop, narrowing possible attack vectors. That said, developer
devices generally aren't publicly exposed to a network and accessible via a
domain name that is probably trivial to enumerate and running CI services like
[Atlassian Bamboo](https://www.atlassian.com/software/bamboo) or
[Jenkins](https://jenkins.io), both of which have been [riddled with security
holes in the
past](https://confluence.atlassian.com/bamboo/bamboo-security-advisory-2017-03-10-876857850.html).
This is the reality for larger, more "enterprise" companies that have chosen to
not migrate to newer cloud-hosted, container-based tools like TravisCI or
CircleCI.

Even for the hip companies that have, one set of credentials to such services
can expose the secrets of all of them. TravisCI supports defining secrets in the
web browser that can anyone logging in can alter unless the administrator has
segregated access on a need-to-know basis. It also supports encrypting secrets
with a Ruby Gem on a developer's device, but that requires quite a few
developers to have access to the key if multiple team members are expected to
manage the pipeline.

---

As DevOps advocates like to point out, it is a methodology and not a job title.
It's getting developers and operations communicating more efficiently and these
days often leads to operations creating a "self-serving" architecture where
developers needn't fill out a form, hand it over to operations, and hopefully
have their code running on production servers months and months down the line.
They should be able to define a Dockerfile, pair-program with a more
operations-minded developer to knock out a Helm chart, and then push the code
into CI, all resulting in a quick turnaround.

Centralisation is a common point of debate in information security circles.
Centralising eases patching, monitoring, and allows security engineers to focus
hardening against one place, but also puts many eggs in one basket.
Decentralisation, if done well, can isolate damage caused by compromises but can
frustrate the aforementioned benefited areas of centralisation.  Centralising
software but decentralising the actual services and hardware can keep things
easier to manage while creating isolation layers. For example, standardising on
Windows 10 Enterprise for your server OS yet ensuring services run on separate
instances can give the benefits of both. That said, a zero-day exploit against
the Windows NT kernel can still end up wrecking _all_ of the services, so just
decentralising the instances but retaining software hemogeny is not a panacea.
However, do we really want to deal with different OSes, unsynchronised logging
systems, myriad monitoring solutions, and incompatible cloud providers when
trying to narrow down a compromise origin? A balance must be struck.

Decentralising services and orchestrating them in a centralised way should be
treated the same as centralised services unless fine-grained access controls and
isolation layers have been set up in the orchestrator. Frankly, most CI setups
do not have this.  They should and most of their documentation encourages it,
but most don't have it in practice. Also, individual security controls on
instances mean a lot less if you've centralised your provisioning onto a single
cloud provider, say AWS, and the administrative credentials for that are
compromised.

---

Locking down cloud provider accounts, especially administrators and the root
account, has therefore become common practice as has the growth of using the
more fine grained access controls the providers give us like AWS's IAM service.
Most CIs installations aren't so rigouress. An awful lot of online tutorials say
"put your infrastructure credentials into your pipeline so Terraform can setup
the provider resources". If SSH-based deployments are used like Ansible, SSH
keys can end up in questionable places like inside the CI agent's image, stored
as reversible or overridable secrets, or even worse, put as plaintext into a
repository somewhere.

Driving the point about centralisation home, it's probably easier to compromise
the CI to gain access to all services than it is to compromise each individual
service one-by-one. Companies also tend to provide more access to the CI than to
AWS; while AWS is seen as being for operations staff only, separate development
teams self-managing CI setups is often lauded as being part of "DevOps culture"
regardless of how accurate that claim is.

---

CIs give a lot of benefit to modern technology companies, so countering these
problems by removing CIs will not and should not be the solution. Instead they
should be secured as the sensitive systems they are: accessing secrets like AWS
credentials and SSH keys should be done ideally through temporary tokens rather
than hardcoded credentials; access should be provided on a need to know basis,
giving smaller teams deployment access _only_ to the projects they maintain
rather than being a member of a generic "developers" access group; and the CI
server itself should be hardened as appropriate for highly sensitive services.

If a team goes for a cloud CI rather than a self-hosted option, as is
increasingly the case, they should have full confidence in their provider and
have a plan for quick revocation of credentials and tokens should the cloud
service get compromised.

Don't harden your services only to leave the front door open to the tool with
the key under the mat for the whole underling infrastructure.
