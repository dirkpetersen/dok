# Claude Code Tutorial: Project Development Workflow

This tutorial walks you through the complete workflow for developing a project using Claude Code with the Haiku → Sonnet → Opus escalation strategy.

## Overview: The Three-Model Workflow

The recommended workflow uses three Claude models in sequence:

1. **Sonnet** - Planning phase: discovers tasks and requirements
2. **Opus** - Validation phase: validates plan and asks additional questions
3. **Sonnet** - Coding phase: implements the project based on final plan

This approach ensures thorough planning before coding begins.

## Step 1: Initialize Your Project

### Create Empty Project Folder

```bash
mkdir my-awesome-project
cd my-awesome-project
git init
```

### Write a Comprehensive README

```bash
nano README.md
```

In the README file, describe your project in detail:

```markdown
# Project Title

## What You Want to Accomplish

[Describe the overall goal and vision]

## Goals

- [Goal 1: specific, measurable outcome]
- [Goal 2: specific, measurable outcome]
- [Goal 3: specific, measurable outcome]

## Technology Preferences

- Language: Python
- Framework: [if applicable]
- Key libraries: [list any preferences]

## Input Data/Source

- Data source: [API, file, website, etc.]
- Format: [JSON, CSV, etc.]
- Location: [URL or path]

## Expected Output

- Format: [What should the output look like?]
- Destination: [File, database, API, etc.]
- Processing steps: [High-level description of processing]

## Additional Details

[Any other important details about the project]
```

**Example: Weather Data Analyzer**

```markdown
# Weather Data Analyzer

## What You Want to Accomplish

Create a tool that fetches weather data from OpenWeatherMap API, analyzes temperature trends, and generates a weekly report with predictions.

## Goals

- Fetch hourly weather data for the past 7 days
- Identify temperature trends and patterns
- Generate a visual chart of temperature progression
- Output a markdown report with predictions

## Technology Preferences

- Language: Python 3.12
- Data analysis: Pandas, NumPy
- Visualization: Matplotlib
- HTTP requests: Requests library

## Input Data/Source

- OpenWeatherMap API (free tier)
- Coordinates: San Francisco (37.7749, -122.4194)
- Data format: JSON API responses

## Expected Output

- A markdown report (weather_report.md) with:
  - 7-day temperature summary
  - Line chart showing temperature trend (embedded as image)
  - Temperature prediction for next 3 days
  - Severe weather alerts if any

## Additional Details

- Use UTC timezone for all timestamps
- Handle API rate limiting gracefully
- Cache responses locally to minimize API calls
- Should run as a standalone script with no arguments
```

Save the file: `Ctrl+X`, then `Y`, then `Enter`.

## Step 2: Create CLAUDE.md Project Context

### Create CLAUDE.md File

Before launching Claude Code, create a CLAUDE.md file to provide project-wide context. This file gives Claude comprehensive information about your project and is always loaded when Claude Code runs.

```bash
nano CLAUDE.md
```

In the CLAUDE.md file, provide detailed project context:

```markdown
# Project Name

## Project Overview

[Brief description of what this project does and its purpose]

## Architecture

[Key components, modules, and how they interact]

## Technology Stack

- Language: Python 3.12
- Key libraries: [list dependencies]
- Framework: [if applicable]

## Coding Conventions

- [Code style guidelines]
- [Naming conventions]
- [File organization patterns]

## Implementation Plan

### Phase 1: Core Functionality
- [ ] Task 1
- [ ] Task 2

### Phase 2: Additional Features
- [ ] Task 3
- [ ] Task 4

## Testing Strategy

[How to test the code]

## Additional Notes

[Any other important context for Claude Code]
```

**Example CLAUDE.md for Weather Data Analyzer:**

```markdown
# Weather Data Analyzer

## Project Overview

Python tool that fetches weather data from OpenWeatherMap API, analyzes temperature trends, and generates weekly reports with predictions.

## Architecture

- `weather_fetcher.py` - API client for OpenWeatherMap
- `analyzer.py` - Temperature trend analysis using Pandas
- `visualizer.py` - Chart generation with Matplotlib
- `reporter.py` - Markdown report generation
- `main.py` - Entry point, orchestrates workflow

## Technology Stack

- Language: Python 3.12
- Data: Pandas, NumPy
- Visualization: Matplotlib
- HTTP: Requests library
- API: OpenWeatherMap (free tier)

## Coding Conventions

- Use type hints for all function parameters and return values
- Follow PEP 8 style guide
- Store API key in environment variable (OPENWEATHER_API_KEY)
- Cache API responses locally in .cache/ directory

## Implementation Plan

### Phase 1: Data Fetching
- [ ] Create OpenWeatherMap API client
- [ ] Implement response caching
- [ ] Add rate limiting protection
- [ ] Handle API errors gracefully

### Phase 2: Analysis
- [ ] Load data into Pandas DataFrame
- [ ] Calculate 7-day temperature statistics
- [ ] Identify trends and patterns
- [ ] Generate 3-day predictions

### Phase 3: Visualization & Reporting
- [ ] Create line chart of temperature progression
- [ ] Generate markdown report with embedded chart
- [ ] Include severe weather alerts

## Testing Strategy

- Manual testing with San Francisco coordinates (37.7749, -122.4194)
- Expected output: weather_report.md with chart and predictions
- Verify caching works by checking .cache/ directory
- Test rate limiting by making multiple rapid requests
```

Save the file: `Ctrl+X`, then `Y`, then `Enter`.

### Launch Claude with Sonnet Model

```bash
claude sonnet
```

Once Claude Code starts, it will automatically load the CLAUDE.md file and understand your project context.

### Review and Refine Project Plan

With CLAUDE.md loaded, Claude now understands your project. You can interact with it to refine the plan:

```
Can you review the implementation plan in CLAUDE.md and suggest any improvements?
```

Claude will:
- Analyze your project structure
- Validate the implementation plan
- Suggest improvements or missing tasks
- Identify potential issues

If Claude suggests changes, you can update CLAUDE.md either by:
- Asking Claude to update it: "Please update CLAUDE.md with your suggestions"
- Manually editing it in another terminal: `nano CLAUDE.md`

## Step 3: Validate with Sonnet Questions

### Ask Claude for Clarification

In the Claude Code session, ask:

```
Do you have any questions about this project before we proceed?
```

Claude will ask 5-10 clarifying questions. **Answer all questions in a single line format:**

```
1. [Answer to question 1] 2. [Answer to question 2] 3. [Answer to question 3] 4. [Answer to question 4] 5. [Answer to question 5]
```

**Example response:**
```
1. Use Python 3.12 2. Store in SQLite database 3. Run daily via cron 4. Include error logging 5. Keep dependencies minimal
```

### Continue Clarification Loop

After you answer, ask again:

```
Do you have more questions?
```

Keep answering until Claude says it has no more questions. This ensures complete understanding before coding.

## Step 4: Deep Review with Opus

### Switch to Opus Model

If you want a more thorough architectural review, switch to the Opus model:

```
/model opus
```

Then ask Opus to review your plan:

```
Can you review the CLAUDE.md file and the overall project architecture? Do you see any edge cases, potential issues, or optimizations we should consider?
```

Opus will:
- Review the implementation plan
- Identify edge cases
- Ask additional architectural questions
- Suggest optimizations

### Answer Opus Questions

Same process as Step 3 - answer all questions in one line:

```
1. [Answer] 2. [Answer] 3. [Answer] ...
```

### Continue Until Complete

Keep asking "Do you have more questions?" until Opus is satisfied. This final validation ensures the plan is bulletproof.

## Step 5: Code Implementation with Sonnet

### Switch Back to Sonnet

```
/model sonnet
```

### Start Coding

```
Please start coding this project now. After you're done, execute it and debug any issues.
```

Sonnet will:
1. Create all necessary files
2. Write complete, production-ready code
3. Execute the code to test it
4. Fix any runtime errors
5. Provide a summary of what was created

Wait patiently. Complex projects may take 10-20+ minutes.

## Step 6: Review and Debug

### Monitor the Output

Watch for:
- File creation messages
- Execution output
- Error messages (if any)
- Success confirmations

### If Errors Occur

If Sonnet encounters errors:

```
I see there's an error. Can you please fix this and try again?
```

Sonnet will:
- Analyze the error
- Fix the code
- Re-execute
- Confirm success

### For Complex Errors

If Sonnet can't fix an error, escalate to Opus:

```
/model opus

This error is complex. Can you review and suggest a fix?
```

Opus will provide deeper analysis and solutions.

## Complete Example Walkthrough

### Starting State
```bash
$ mkdir weather-analyzer
$ cd weather-analyzer
$ git init
$ nano README.md
# [write your README as shown above]
# [save and exit]
$ claude sonnet
```

### In Claude Code Session

```
# Create CLAUDE.md first (as shown in Step 2)
nano CLAUDE.md
# [write comprehensive project context]
# [save and exit]

# Launch Claude Code with Sonnet
claude sonnet
```

*[Claude automatically loads CLAUDE.md]*

```
Can you review the implementation plan and let me know if you have any questions about this project?
```

Claude asks: "Should the report include severity levels for weather alerts? Should predictions use machine learning or simple linear extrapolation? Should the script support multiple cities?"

Your response:
```
1. Include severity levels (Critical/Warning/Info) 2. Use simple linear extrapolation 3. Single city only for MVP
```

```
Do you have more questions?
```

Claude: "Just one more - how should we handle missing data points?"

Your response:
```
1. Use forward fill method for missing data
```

```
Do you have more questions?
```

Claude: "I believe I have all the information needed to create a solid plan."

Now switch models for deeper review:

```
/model opus

Can you review the CLAUDE.md file and provide architectural feedback?
```

*[Opus reviews and asks additional questions]*

After Opus is satisfied and you've updated CLAUDE.md with any improvements:

```
/model sonnet

Please start coding this project now. After you're done, execute it and debug any issues.
```

*[Wait 10-20 minutes for implementation]*

### Result

You now have:
- ✅ Complete weather analyzer script
- ✅ Fully tested and working code
- ✅ Error handling and logging
- ✅ Documented functions
- ✅ Ready for production or further enhancement

## Tips for Success

### Planning Phase Tips

1. **Be specific** - Vague requirements lead to confused AI models
2. **Include examples** - Show what input/output should look like
3. **Mention constraints** - Budget, time, performance requirements
4. **List edge cases** - What shouldn't break the system?
5. **Define success** - How do you know it works?

### Question Phase Tips

1. **Answer quickly** - Don't overthink responses
2. **Be concise** - Use one-liners, not paragraphs
3. **Clarify assumptions** - If Claude assumes wrong, correct it
4. **Ask for confirmation** - "Does that match your expectation?"

### Coding Phase Tips

1. **Stay patient** - Complex projects take time
2. **Don't interrupt** - Let Claude complete the implementation
3. **Review output** - Check the generated code makes sense
4. **Test thoroughly** - Claude tests but you should too
5. **Iterate if needed** - Ask for improvements after first run

### Escalation Guide

**Use Haiku for:**
- Simple bug fixes
- Small code additions
- Quick questions

**Use Sonnet for:**
- New feature development
- Planning and architecture
- Most general coding tasks

**Use Opus for:**
- Complex problem-solving
- Architectural review
- Difficult debugging
- When Sonnet gets stuck

## Common Patterns

### "Don't start coding yet" Instruction

After the planning phase is complete but before implementation, you can say:

```
Don't start coding yet. I want to make sure we have the right approach.
Do you have any final questions about the plan?
```

This ensures perfect clarity before coding begins.

### Handling Unexpected Issues

If Claude makes incorrect assumptions:

```
I notice you're assuming [wrong assumption]. Actually, [correct information].
Can you adjust the plan accordingly?
```

### Requesting Specific Technologies

During planning questions, you can be very specific:

```
1. Must use FastAPI 2. Must use PostgreSQL 3. Must include Docker 4. Must have comprehensive logging 5. Must pass type checking with MyPy
```

## Workflow Checklist

- [ ] Created project directory and git initialized
- [ ] Wrote comprehensive README.md with all project details
- [ ] Created CLAUDE.md file with project context and implementation plan
- [ ] Launched Claude Code with Sonnet model
- [ ] Reviewed and refined the implementation plan with Sonnet
- [ ] Answered all Sonnet clarification questions
- [ ] Switched to Opus for deeper architectural review (optional)
- [ ] Answered all Opus clarification questions
- [ ] Updated CLAUDE.md with final improvements
- [ ] Switched back to Sonnet for implementation
- [ ] Ran and debugged the code
- [ ] Tested the output thoroughly
- [ ] Project complete and committed to git

## Next Steps

After implementing your project:

1. **Test thoroughly** - Try edge cases and error conditions
2. **Commit to git** - Save your work with descriptive commit messages
3. **Iterate** - Ask Claude for improvements or new features
4. **Deploy** - Put your project to work in the real world
5. **Maintain** - Use Claude Code for ongoing improvements

## Troubleshooting

### Claude Code won't start

```bash
# Ensure AWS credentials are set
echo $AWS_PROFILE  # Should be "bedrock"

# Test Bedrock access
aws bedrock list-foundation-models --region us-west-2 --profile bedrock
```

### CLAUDE.md not being loaded

```bash
# Make sure you're in a git repository
git status  # Should show git repository info

# Make sure CLAUDE.md exists in the project root
ls -la CLAUDE.md

# Restart Claude Code to reload CLAUDE.md
# Exit current session (Ctrl+D) and run:
claude sonnet
```

### Model switching issues

```bash
# Always ensure you're in a Claude Code session first
claude sonnet

# Then switch models
/model opus

# Ask a question to engage the model
Can you help me review this code?
```

### Timeouts on large projects

Large projects may take 20-30 minutes. This is normal. Don't interrupt the process.

## FAQ

**Q: Should I write both README.md and CLAUDE.md?**
A: Yes. README.md is for humans (project documentation), while CLAUDE.md is for Claude Code (project context and implementation guidance). They serve different purposes.

**Q: Can I skip creating CLAUDE.md and just use README.md?**
A: You can, but CLAUDE.md provides better results because it's specifically designed for Claude Code with implementation plans, coding conventions, and architecture details that aren't usually in a README.

**Q: Can I skip the Opus review?**
A: You can, but we recommend it for important projects. Opus often catches issues Sonnet misses.

**Q: What if I don't like the generated code?**
A: Ask Claude to rewrite specific sections or adjust the approach.

**Q: Can I use this for really large projects?**
A: Yes! Complex projects may take longer (20-40 minutes), but Claude can handle them.

**Q: What if Claude gets stuck?**
A: Try escalating to a more capable model (Opus) or simplify the task scope.