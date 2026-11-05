# Contributing to FromThePage

Thanks for your interest in FromThePage!  We're excited that you'd like to improve this open-source tool which has been installed on six continents.  If you'd like something small to start, check out issues labelled [good first issue](https://github.com/benwbrum/fromthepage/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22).

# Issues

Please open an issue before creating a pull request, even if the feature has been discussed via email or Slack.  If possible, include a link to an example of the problem.


# Pull Requests
Please create a branch off of `development`.  The branch name should start with the issue number.

All commit messages should include the issue number.

All pull requests should be linked to an issue, ideally using closing keywords.

## AI-assisted contributions
FromThePage welcomes contributions made with the help of AI tools (e.g. Claude Code, GitHub Copilot, ChatGPT, Cursor).  We do require that AI use be disclosed explicitly.

* **Disclose it.**  If AI tools generated or substantially shaped any part of your pull request (code, tests, documentation, or the PR description itself), fill in the "AI Disclosure" section of the pull request template.  Name the tool/model and describe what it was used for.  Simple autocomplete of a few tokens does not need disclosure; anything beyond that does.
* **Keep attribution.**  If your tool adds a `Co-Authored-By:` trailer or similar attribution to commits, leave it in place.
* **You are responsible for the change.**  You must review, run, and understand every line you submit, and be able to answer reviewer questions about it.  "The AI wrote it" is not an answer in code review.
* **Test it.**  AI-assisted changes are held to the same standard as any other: include specs covering new code and make sure CI passes.
* **Mind licensing.**  Do not submit code you have reason to believe is copied from a source with an incompatible license.  All contributions are made under this project's [LICENSE](LICENSE).
* **Protect data.**  Never paste secrets, credentials, or non-public user data from a FromThePage installation into an AI tool.

Pull requests that appear to be AI-generated but are not disclosed may be closed.

## Coding conventions
* Indentation is via two spaces.  
* We prefer [slim templates](https://slim-template.github.io/), but ERB is acceptable.

