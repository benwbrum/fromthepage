You are an experienced software developer tasked with addressing a GitHub issue. Your goal is to analyze the issue, understand the codebase, and create a comprehensive plan to tackle the task. Follow these steps carefully:

1. First, review the GitHub issue 

2. Next, examine the relevant parts of the codebase.

Analyze the code thoroughly until you feel you have a solid understanding of the context and requirements.

3. Create a new branch from the `development` branch for this issue. The branch name should start with the issue number and be descriptive. Use the following format: [issue-number]-brief-description (e.g. `6001-update-puppeteer`). Every commit message must include the issue number (e.g. `#6001 Pin Puppeteer to 24.43.1`).

4. Create a comprehensive plan and todo list for addressing the issue. Consider the following aspects:

   - Required code changes
   - Potential impacts on other parts of the system
   - Necessary tests to be written or updated
   - Documentation updates
   - Performance considerations
   - Security implications
   - Backwards compatibility (if applicable)
   - Inlcude the reference link to faeturebase or any opther link that has the source of the user request

5. Think deeply about all aspects of the task. Consider edge cases, potential challenges, and best practices for implementation.

6. Document your plan in the following format:

<plan>
[Your comprehensive plan goes here. Include a high-level overview followed by a detailed breakdown of steps.]
</plan>

Remember, your task is to create a plan, not to implement the changes. Focus on providing a thorough, well-thought-out strategy for addressing the GitHub issue. Then ASK FOR APPROVAL BEFORE YOU START WORKING on the TODO LIST.

7.  We are diligently working to improve our test coverage.  Please make sure to include tests that cover any new lines of code you add.  If possible, adding tests that improve test coverage for closely related areas of the code would be great as well.

8.  FromThePage Notes:
   We have multiple types of users in FromThePage:  Transcribers see and transcribe public collections in FromThePage.  Project Owners create collections, upload material and change their settings.  (Trial users are a special type of Project Owner and are flagged as such.  They have the same access a Project Owner does, with some upload restrictions and additional messages.)  Staff are added as Owners to a specific collection, which then gives them the ability to create more collections under the original project owner's account.  For staff, the like_owner? method in the user model can be used to determine if a user should see owner sorts of things for the objects in FromThePage.  Administrators or Admins are FromThePage staff that can see system wide settings and can log in as any user.  Administrators often are Project Owners as well.

9.  Code Quality:
   Always run `bundle exec rubocop -A` to fix syntax errors and style issues before committing code changes. This ensures consistent code formatting and catches potential issues early.

10.  AI Disclosure:
   FromThePage accepts AI-assisted contributions but requires explicit disclosure (see "AI-assisted contributions" in CONTRIBUTING.md). Every pull request you open or draft must fill in the "AI Disclosure" section of `.github/pull_request_template.md`, naming GitHub Copilot (and the model, if known) and describing what it was used for. Never remove AI attribution trailers from commits.

## New Relic read-only access

For explicitly authorized telemetry work, follow the [New Relic setup and access smoke-test runbook](../doc/new_relic_agent_access.md).
An operator must configure `NEW_RELIC_API_KEY` as an **Agents** secret and `NEW_RELIC_ACCOUNT_ID` as an **Agents** variable under **Settings → Secrets and variables → Agents**, confirm the region, and allow only its API host under **Settings → Copilot → Internet access**.
These values become environment variables for cloud/coding agent execution tools, not every github.com chat; start a fresh cloud agent session after saving.
Use a User API key whose owner's permissions a human has verified as least-privilege/read-only; a key name does not restrict permissions.
Never expose credentials, attempt mutations to test permissions, or disable the firewall. Run the linked smoke-test prompt only when requested.
