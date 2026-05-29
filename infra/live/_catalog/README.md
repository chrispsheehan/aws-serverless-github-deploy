# `_catalog`

This directory is the canonical full infrastructure catalog.

Use it as the source menu when deciding which stacks a real environment should include. `dev` and `prod` can be smaller deployable subsets of this catalog, while `_catalog` remains the broad reference shape.

## Human And Agent Note

- Treat `infra/live/_catalog` as the menu/source for optional platform capabilities.
- The leading underscore marks this as a catalog, not a normal deploy target like `dev` or `prod`.
- Do not assume every stack in `_catalog` must be deployed to `dev` or `prod`.
- When creating or simplifying a real environment, copy or keep only the selected stack subset from this catalog and preserve the required dependency closure.
- Do not modify `infra/live/dev`, `infra/live/prod`, or `infra/modules` when adjusting this catalog unless the user explicitly asks for a live environment or module contract change.
- If you run Terragrunt directly against this catalog, the environment name is derived from the path by `infra/root.hcl`, so these stacks write state under `_catalog/aws/<stack>/terraform.tfstate`.

Plans can use mock dependency outputs before upstream stacks exist. Do not apply a saved plan that captured mocks; re-plan after real upstream outputs exist.
