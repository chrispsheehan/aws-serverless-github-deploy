# App Shaping Flow

Use this shared flow when adapting an external app, replacing the placeholder app, simplifying the template, or bootstrapping a new app from this repo.

- first determine whether the work is additive or replacement unless the intent is already clear
- when the target repo is empty or effectively empty, enter this flow immediately; treat a repo as effectively empty when it has no meaningful app, infra, runtime, or workflow code beyond placeholders, starter files, or minimal scaffolding
- determine the selected app capabilities, such as frontend, backend API, batch/worker runtime, database, auth, messaging, containers/ECS, Lambda, scheduled jobs, or static hosting
- ask only the missing app-shaping questions that are not already answered in `BOOTSTRAP_DECISIONS.md`
- persist durable bootstrap, simplification, replacement, and capability-selection answers in `BOOTSTRAP_DECISIONS.md` so they do not need to be asked repeatedly
- before asking a recorded app-shaping question, check `BOOTSTRAP_DECISIONS.md` first and reuse the recorded answer unless the user changes it
- if the user gives an answer that conflicts with an existing entry in `BOOTSTRAP_DECISIONS.md`, warn that the recorded decision is changing, then update the file
- if the user says the work is replacement, remove placeholder/demo code, docs, local services, infra stacks, workflow surface, and stale runtime paths that no longer serve the selected app shape
- do not keep unused demo capabilities just because they existed in the template
- do not delete or replace template/example code solely because a new feature request could be implemented more cleanly without it; replacement intent or a recorded decision must be clear
- keep or remove unused capabilities based on the recorded decision, and do not assume unmentioned capabilities should stay forever
- still confirm before removing expensive or shared infrastructure capabilities, such as load balancers, ECS clusters, databases, Cognito, Route53/CloudFront, or messaging, unless the user explicitly names them for removal
- when removal would affect major capabilities, briefly list what would remain and what would be removed before editing
- align local development, workflows, infra stacks, runtime code, docs, and verification commands with the selected app shape
- for AWS-backed deployment shapes, offer to check required deployment prerequisites at the point the selected environment/domain is known; expected checks include the VPC, tagged subnets, and Route53 hosted zone required by the selected domain
- before relying on a hosted zone, confirm the intended hosted zone name with the user and verify it matches the selected `domain_name`/frontend domain shape
- always consider security during app shaping; if a proposed API would be exposed to the public internet, say that explicitly and suggest at least one more secure option
- do not assume a public unauthenticated API is acceptable just because it is the simplest technical shape
- before closing an app-shaping task, explicitly name what remains, what was removed, what still needs operational setup, and any bootstrap commands the user should run
- at the end of a bootstrap, simplification, or replacement flow, offer to update the README and related context docs so they describe the selected app rather than the original template
- when replacement or bootstrap intent is confirmed, the root README title should become the app/product/repo name rather than a template name; if the right title is not obvious, ask the user to confirm it before renaming the title
- remove or rewrite stale references to "template", "placeholder", "boilerplate", demo apps, and unused capabilities in human-facing docs unless the reference is still intentionally describing this repo's reusable scaffolding behavior
- review all relevant README/docs at that point for human readability and agent parsability: clear title, short purpose statement, current capability list, accurate "read next" links, no stale runtime paths, and enough ownership/routing detail for future agents to load only the needed context
- when doc titles, product name, or app positioning are subjective, check the proposed title or naming with the user before making broad doc rewrites
