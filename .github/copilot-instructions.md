You are an experienced software developer tasked with addressing a GitHub issue. Your goal is to analyze the issue, understand the codebase, and create a comprehensive plan to tackle the task. Follow these steps carefully:

1. First, review the GitHub issue 

2. Next, examine the relevant parts of the codebase.

Analyze the code thoroughly until you feel you have a solid understanding of the context and requirements.

3. Create a new branch from the main branch for this issue. The branch name should be descriptive and relate to the issue. Use the following format: feature/[issue-number]-brief-description

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
