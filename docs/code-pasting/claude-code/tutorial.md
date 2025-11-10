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

## Step 2: Planning with Sonnet

### Launch Claude with Sonnet Model

```bash
claude sonnet
```

### Run Project Initialization

Once Claude Code is running:

```
/model sonnet
/init
```

Claude will:
- Read the README.md file
- Analyze your requirements
- Create a project inventory
- Generate a CLAUDE.md file with implementation tasks

Wait for Claude to complete the analysis. You should see:
- List of identified tasks
- File structure recommendations
- Implementation strategy

### Review Generated CLAUDE.md

Open the generated CLAUDE.md file in another terminal:

```bash
cat CLAUDE.md
# or edit if needed
nano CLAUDE.md
```

This file contains:
- Task breakdown
- Implementation steps
- Configuration notes
- Testing strategy

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

```
/model opus
/init
```

Opus will:
- Review Sonnet's plan
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
/model sonnet
/init
```

*[Wait for analysis to complete]*

```
Do you have any questions about this project?
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

Now switch models:

```
/model opus
/init
```

*[Opus reviews and asks additional questions]*

After Opus is satisfied:

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
- [ ] Ran Sonnet with `/init` to generate plan
- [ ] Reviewed generated CLAUDE.md file
- [ ] Answered all Sonnet clarification questions
- [ ] Ran Opus with `/init` for additional validation
- [ ] Answered all Opus clarification questions
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

### /init command doesn't work

```bash
# Make sure you're in a git repository
git status  # Should show git repository info

# Make sure README.md exists
ls -la README.md
```

### Model switching issues

```bash
# Always ensure you're in a Claude Code session first
claude sonnet

# Then switch models
/model opus
/init
```

### Timeouts on large projects

Large projects may take 20-30 minutes. This is normal. Don't interrupt the process.

## FAQ

**Q: Do I need to write the README perfectly?**
A: No! The more detail the better, but Claude will ask clarifying questions if needed.

**Q: Can I skip the Opus review?**
A: You can, but we recommend it for important projects. Opus often catches issues Sonnet misses.

**Q: What if I don't like the generated code?**
A: Ask Claude to rewrite specific sections or adjust the approach.

**Q: Can I use this for really large projects?**
A: Yes! Complex projects may take longer (20-40 minutes), but Claude can handle them.

**Q: What if Claude gets stuck?**
A: Try escalating to a more capable model (Opus) or simplify the task scope.