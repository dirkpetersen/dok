# Code Pasting

Modern software development through articulate requirements and AI-assisted tooling.

## Philosophy

In 2025, effective software development is fundamentally about **clear communication of requirements**. The traditional approach of typing code directly is being augmented (and often replaced) by a more refined process:

1. **Articulate Requirements** - Express what you need clearly
2. **Document in Markdown** - Use plain text that AI can understand perfectly
3. **Version Control with GitHub** - Maintain organized, collaborative workflows
4. **AI-Assisted Development** - Leverage modern tools like Claude Code
5. **Manage Dependencies** - Handle the complexities of your tech stack

This approach is more effective than "vibe coding" because it enforces clarity, maintainability, and reproducibility.

## Why "Code Pasting"?

The term captures the modern workflow:

- You **articulate** your requirements in markdown
- You **paste** them into an AI tool
- The AI **understands** your needs from clear documentation
- You **paste** the generated code into version control
- You **iterate** with feedback and refinement

It's not about haphazard copying—it's about purposeful, documented development.

## The Four Pillars

### 1. [Markdown](markdown/index.md)

**The Foundation of Communication**

Markdown is the universal language for documentation and requirement specification. When your requirements are in well-structured markdown, AI tools can:
- Parse structure effortlessly
- Understand context precisely
- Generate code that matches your intent
- Help you iterate on specifications

Topics:
- Markdown syntax and best practices
- Documentation patterns
- Requirement specification formats
- Creating effective prompts for AI

### 2. [GitHub](github/index.md)

**Version Control and Collaboration**

GitHub is the backbone of modern development:
- Track requirements and changes
- Collaborate with teams
- Integrate with AI tools
- Maintain history and accountability
- Publish your work

Topics:
- SSH authentication and setup
- GitHub CLI for productivity
- Git workflows and best practices
- Collaboration patterns

### 3. [Claude Code](claude-code/index.md)

**AI-Assisted Development**

Claude Code represents the next generation of development tools:
- Understands complex requirements
- Generates production-ready code
- Operates within git repositories
- Supports multiple AI models (Haiku, Sonnet, Opus)
- Integrates with your AWS infrastructure

Topics:
- Setup with AWS Bedrock
- Model selection and usage
- Integration with git workflows
- Best practices for AI-assisted coding

### 4. [Python](python/index.md)

**The Ecosystem of Science and AI**

Python is the primary ecosystem for AI and scientific computing. While language choice varies by use case, Python's ecosystem deserves special attention:
- ML/AI frameworks (PyTorch, TensorFlow, transformers)
- Scientific computing (NumPy, SciPy, Pandas)
- Data visualization and analysis
- Quirks and best practices unique to Python

Topics:
- Modern Python tooling (UV, Pixi)
- Virtual environments and dependency management
- Common gotchas and solutions
- Integration with AI workflows

## The Workflow

### Step 1: Define Requirements (Markdown)

Write clear, structured requirements in markdown:

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
- Performance <100ms for login
```

### Step 2: Version Control (GitHub)

Commit your requirements to your repository:

```bash
git add requirements.md
git commit -m "Add user authentication requirements"
git push origin main
```

### Step 3: Generate Code (Claude Code)

Paste requirements into Claude Code:

```bash
claude /path/to/project
```

Provide the requirements document to Claude—the tool understands markdown perfectly and can generate code that matches your specification.

### Step 4: Iterate and Refine

- Review generated code
- Commit to GitHub
- Update requirements based on learnings
- Re-run Claude Code with updated specs
- Merge and deploy

## Why This Works

### For AI Tools
- Markdown is unambiguous
- AI can parse structure reliably
- Plain text avoids parsing errors
- Requirements are self-documenting

### For Developers
- Clear specification prevents miscommunication
- Requirements become documentation
- Easy to iterate with AI
- Entire workflow is versionable

### For Teams
- Markdown enables collaboration
- GitHub provides visibility
- AI tools democratize capabilities
- Python ecosystem is well-established

## Best Practices

- ✅ **Document first** - Start with markdown requirements
- ✅ **Be specific** - AI works best with clear specs
- ✅ **Use examples** - Show what success looks like
- ✅ **Version everything** - Git all requirements and code
- ✅ **Iterate together** - Refine with AI feedback
- ❌ **Don't assume** - Always specify constraints
- ❌ **Skip documentation** - Markdown IS the foundation
- ❌ **Ignore edge cases** - Specify them in requirements

## Getting Started

1. Start with [Markdown](markdown/index.md) to understand documentation best practices
2. Set up [GitHub](github/index.md) for version control
3. Configure [Claude Code](claude-code/index.md) for AI-assisted development
4. Explore [Python](python/index.md) if building AI/ML projects

## The Future of Development

This approach represents how software development is evolving in 2025:

- **Less typing** - AI handles code generation
- **More thinking** - Clear specification is paramount
- **Better collaboration** - Documentation enables team understanding
- **Faster iteration** - AI suggests, you refine
- **Reproducible workflows** - Everything is documented and versioned

By mastering these four pillars, you're not just keeping up with development trends—you're leading the way.
