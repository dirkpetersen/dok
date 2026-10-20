# Code Pasting

Modern software development with clear requirements and an AI agent that writes the code.

## Quick Start

Set up a complete development workstation with one command:

```bash
curl -fsSL "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/dev-station-install.sh" | bash
```

This installs the shell configuration, the AWS CLI, Node.js and the Claude Code wrapper. You do not need sudo.

!!! tip "Full interactive setup"
    For a complete setup with SSH keys, GPG signing and Git configuration:
    ```bash
    curl -fsSL "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/dev-station-install.sh" | bash -s -- --full
    ```

## Philosophy

The agent now writes most of the code, and it also selects the programming language. Your work is different:

1. **Tell the agent what you need.** Write clear requirements in Markdown.
2. **Keep everything in Git.** Requirements, code and history go to GitHub.
3. **Let the agent do the work.** Claude Code reads the requirements and writes the code.
4. **Understand and check the result.** Ask for output that is easy to read: technical English, diagrams and web pages.

Step 4 becomes more important each year. When the agent does more of the work, your main job is oversight and understanding.

This method is better than "vibe coding" because it is clear, it is easy to maintain and you can repeat it.

## Why "Code Pasting"?

The name describes the workflow:

- You **write** your requirements in Markdown.
- You **paste** them into the agent.
- The agent **writes** the code from the requirements.
- You **check** the result and **commit** it to version control.
- You **repeat** with feedback until the result is correct.

It is not careless copying. It is development with a clear specification.

## The Four Pillars

### 1. [Markdown](markdown/index.md)

**The language of requirements**

Markdown is plain text with a simple structure. Humans can read it easily and agents can parse it reliably. Good requirements in Markdown give you code that matches what you need.

- Markdown syntax and good practices
- Documentation patterns
- Requirement formats
- Effective prompts for an agent

### 2. [GitHub](github/index.md)

**Version control and collaboration**

GitHub keeps the history of your requirements and your code. It lets you work with a team and with agents.

- SSH authentication and setup
- GitHub CLI
- Git workflows
- Collaboration patterns

### 3. [Claude Code](claude-code/index.md)

**The agent that does the work**

Claude Code works in your Git repository. It reads your requirements, writes and changes code, runs commands and tests, and commits the result.

- Setup with a claude.ai login, AWS Bedrock, Azure AI Foundry or a local LLM
- Model selection (Haiku, Sonnet, Opus, Fable)
- The `claude` wrapper and its permission modes
- A complete [tutorial](claude-code/tutorial.md)

### 4. [Tips for Claude Code](tips/index.md)

**Understand what the agent did**

The agent can write more code than you can read. These tips make its output easier to understand and check:

- Ask for **technical English** (ASD-STE100) to get short, clear text.
- Use **sliders**, for example "80% of the way to ASD-STE100", to set how strict the style is.
- Put your style rules in **CLAUDE.md** so that they apply to each session.
- Ask for **diagrams**, **web pages** and **explainer videos** when text is not the best format.
- Make **discardable software** that helps you understand one problem.

## The Workflow

### Step 1: Write the requirements (Markdown)

```markdown
# Feature: User Authentication

## Requirements
- Support email/password login
- Implement password reset flow
- Add rate limiting

## Constraints
- Must support OAuth2
- Needs TOTP support
- Database: PostgreSQL

## Success Criteria
- All tests pass
- Login takes less than 100 ms
```

### Step 2: Commit them (GitHub)

```bash
git add requirements.md
git commit -m "Add user authentication requirements"
git push origin main
```

### Step 3: Let the agent do the work (Claude Code)

Start Claude Code in the project directory and give it the requirements:

```bash
cd ~/my-project
claude
```

```text
Implement the feature in requirements.md. Select a suitable language and framework.
```

### Step 4: Understand and check the result

Do not accept the result without understanding it. Ask the agent to explain it in a format that is easy to check:

```text
Explain what you changed. Use 80% ASD-STE100 and add a Mermaid diagram of the new flow.
```

Then:

- Review the changes and the tests.
- Commit to GitHub.
- Update the requirements with what you learned.
- Repeat.

## Good Practices

**Do:**

- Write the requirements first.
- Be specific. Give constraints and success criteria.
- Give examples of a correct result.
- Keep requirements and code in Git.
- Ask the agent to explain its work in clear technical English.

**Do not:**

- Assume that the agent knows constraints that you did not write down.
- Forget edge cases. Put them in the requirements.
- Accept code that you do not understand.

## Getting Started

1. Learn [Markdown](markdown/index.md) to write good requirements.
2. Set up [GitHub](github/index.md) for version control.
3. Configure [Claude Code](claude-code/index.md) and do the [tutorial](claude-code/tutorial.md).
4. Read the [Tips for Claude Code](tips/index.md) to understand what the agent makes.

## Language Toolchains (Optional)

The agent selects the programming language for each task, so you do not need to learn a language before you start. But some ecosystems have their own tools and problems. If you work with AI, machine learning or scientific computing, see the [Python](python/index.md) page for package managers (UV, Pixi) and environment setup.
