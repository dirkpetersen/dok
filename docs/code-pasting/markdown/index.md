# Code Pasting - Markdown

Markdown as the foundation for AI-readable requirements and documentation.

## Why Markdown?

Markdown is the standard format for:

- **Documentation** - READMEs, guides, and specifications
- **AI Communication** - Clear structure that AI tools parse perfectly
- **Version Control** - Plain text integrates seamlessly with git
- **Knowledge Sharing** - Renders beautifully on GitHub and documentation sites
- **Cross-Platform** - Works everywhere without special tools

## Markdown Fundamentals

### Headings

Structure your content with headings:

```markdown
# Main Title (H1)
## Major Section (H2)
### Subsection (H3)
#### Details (H4)
```

**Rule**: Use one H1 per document. AI tools use heading hierarchy to understand structure.

### Lists

Organize information clearly:

```markdown
# Unordered Lists
- Item one
- Item two
  - Nested item
  - Another nested

# Ordered Lists
1. First step
2. Second step
3. Final step
```

### Code Blocks

Always use fenced code blocks for AI clarity:

```markdown
\`\`\`python
def hello_world():
    print("Hello, World!")
\`\`\`

\`\`\`javascript
console.log("Hello, World!");
\`\`\`
```

**Important**: Always specify the language for syntax highlighting and AI understanding.

### Emphasis

```markdown
*italic* or _italic_
**bold** or __bold__
***bold italic***
~~strikethrough~~
```

### Links and Images

```markdown
[Link text](https://example.com)
[Local link](./other-file.md)
![Alt text](image.png)
```

## Writing AI-Friendly Specifications

When writing requirements for AI tools, follow these patterns:

### Clear Structure

```markdown
# Feature: User Registration

## Overview
Brief description of what the feature does.

## Requirements
- Requirement 1
- Requirement 2
- Requirement 3

## Constraints
- Technical limitation 1
- Technical limitation 2

## Success Criteria
- Measurable outcome 1
- Measurable outcome 2

## Example Usage
\`\`\`python
user = register_user("email@example.com", "password")
assert user.email == "email@example.com"
\`\`\`
```

### Specify Edge Cases

```markdown
## Edge Cases

### Empty Input
- Should return error, not crash

### Special Characters
- Handle @, #, $, etc. properly

### Performance
- Must handle 1000+ users
- Response time < 100ms
```

### Show Examples

```markdown
## Examples

### Successful Registration
\`\`\`
Input: {"email": "user@example.com", "password": "secure123"}
Output: {"user_id": 123, "created_at": "2025-01-01"}
\`\`\`

### Error Handling
\`\`\`
Input: {"email": "invalid-email", "password": "123"}
Output: Error with message explaining validation failure
\`\`\`
```

## Documentation Patterns for Code Pasting

### API Documentation

```markdown
## POST /api/users

Create a new user.

### Request
\`\`\`json
{
  "email": "user@example.com",
  "password": "secure_password",
  "name": "User Name"
}
\`\`\`

### Response
\`\`\`json
{
  "id": "user_123",
  "email": "user@example.com",
  "created_at": "2025-01-01T00:00:00Z"
}
\`\`\`

### Error Cases
- 400: Missing required fields
- 409: Email already registered
- 500: Database error
```

### Function Specification

```markdown
## Function: calculate_discount(price, quantity)

Calculate discount based on quantity purchased.

### Parameters
- `price` (float): Unit price in dollars
- `quantity` (int): Number of units

### Returns
- (float): Final price after discount

### Rules
- Buy 10+: 5% discount
- Buy 50+: 10% discount
- Buy 100+: 15% discount

### Examples
\`\`\`python
calculate_discount(100, 50)  # Returns 900.0 (10% off)
calculate_discount(100, 10)  # Returns 950.0 (5% off)
\`\`\`
```

## Best Practices for AI Communication

### ✅ Do This

- Use clear, simple language
- Break complex ideas into sections
- Provide concrete examples
- Specify all constraints upfront
- Use code blocks for all code
- Include success criteria

### ❌ Don't Do This

- Vague descriptions without examples
- Mixing code with prose without block formatting
- Missing edge cases
- Assuming implicit knowledge
- Using complex sentences when simple ones work
- Forgetting to specify language in code blocks

## Markdown Files in Git

### Structure Your Documentation

```
project/
├── README.md                 # Overview
├── REQUIREMENTS.md           # Feature specifications
├── docs/
│   ├── setup.md             # Installation
│   ├── api.md               # API documentation
│   ├── architecture.md      # System design
│   └── troubleshooting.md   # Common issues
└── .claude.md               # Claude Code guidelines
```

### .claude.md for Code Pasting

Create a `.claude.md` file in your project root:

```markdown
# Claude Code Guidelines

## Project Overview
Brief description of what this project does.

## Key Requirements
- Requirement 1
- Requirement 2

## Architecture
High-level system design.

## Important Constraints
- Must use PostgreSQL
- API responses must be < 100ms
- Python 3.10+

## Common Patterns
\`\`\`python
# Always follow this pattern for database queries
with db.session():
    result = db.query(Model).filter(condition).all()
\`\`\`

## Testing Requirements
- All functions must have tests
- Minimum 80% code coverage
```

## Markdown Resources

- [CommonMark Spec](https://spec.commonmark.org/)
- [GitHub Flavored Markdown](https://github.github.com/gfm/)
- [Markdown Guide](https://www.markdownguide.org/)

## Writing Markdown in Microsoft Word

### Writage Plugin

For users who prefer writing in Microsoft Word, the **Writage plugin** provides seamless markdown support:

**What is Writage?**

Writage is a plugin for Microsoft Word that allows you to:
- Write and edit markdown directly in Word
- Export Word documents to markdown
- Import markdown files and edit in Word
- Maintain markdown formatting and structure
- Use Word's familiar interface for markdown writing

**Installation**

1. Download Writage from [writage.com](https://www.writage.com)
2. Install the plugin (available for Windows)
3. Restart Microsoft Word
4. Writage appears in the Word ribbon

**How to Use Writage**


<img width="298" height="150" alt="image" src="https://github.com/user-attachments/assets/ea44003d-e7f4-4ae5-a2b1-8b861eb37434" />


### Opening Markdown Files

```
File → Open → Select markdown file (.md)
Writage automatically detects and formats as markdown
```

### Creating New Markdown Documents

1. Create new Word document
2. Go to **Writage** ribbon
3. Click **Markdown** mode
4. Write in familiar Word interface
5. Markdown formatting is applied automatically

### Writing with Markdown Awareness

- Use **Heading Styles** for `# ## ###`
- Use **Lists** for bullets and numbering
- Use **Bold/Italic** for `**bold**` and `*italic*`
- Use **Code** style for inline code
- Insert **Tables** naturally - Writage handles markdown conversion

### Exporting to Markdown

```
Writage → Export to Markdown
Choose location and filename
File saved as .md with proper formatting
```

**Benefits of Writage**

- ✅ Use Word's familiar interface
- ✅ Real-time spell check
- ✅ Grammar checking
- ✅ Track changes for collaboration
- ✅ Export clean markdown for AI tools
- ✅ No need to learn markdown syntax
- ✅ Professional document formatting

**Workflow with Writage**

1. **Write Requirements** in Word using Writage
   - Use heading styles naturally
   - Create lists and tables visually
   - Spell/grammar check built-in

2. **Export to Markdown** from Writage
   - Automatic conversion to `.md` format
   - All formatting preserved

3. **Commit to GitHub**
   - Pure markdown files in version control
   - Easy for AI tools to parse

4. **Paste into Claude Code**
   - Perfectly formatted requirements
   - Claude understands structure exactly

### Tips for Best Results

- Use consistent **Heading Styles** (Heading 1, 2, 3)
- Use **Bullet Lists** instead of typing dashes
- Create **Tables** using Word's table tools
- Use **Code** style for snippets
- Avoid complex formatting (colors, custom fonts)
- Keep structure simple and hierarchical

### Limitations

- ⚠️ Available for Windows only (not macOS)
- ⚠️ Some complex Word features don't convert to markdown
- ⚠️ Keep to standard markdown elements for best results
- ⚠️ Test export before committing to GitHub

## Alternative: Direct Markdown Editing

If Writage isn't suitable, other options include:

- **VS Code** - Lightweight, free, excellent markdown support
- **Typora** - Markdown-first editor with live preview
- **Obsidian** - Knowledge management with markdown
- **Notion** - Cloud-based with markdown support
- **GitHub Web Editor** - Edit directly in browser

## Rendering and Sharing

### GitHub

Markdown files render automatically on GitHub:

```
README.md → Displayed on repository main page
docs/*.md → Browsable documentation
.claude.md → Guidelines for AI tools
```

### Documentation Sites

Use tools to create documentation sites:

- **MkDocs** - This documentation uses MkDocs
- **Sphinx** - Python documentation standard
- **Hugo** - Static site generator

## The Markdown-First Workflow

1. **Write Requirements** in markdown (Word with Writage or your preferred editor)
2. **Commit to GitHub** for version history
3. **Paste into Claude Code** for code generation
4. **Review Output** and iterate
5. **Commit Code** with markdown specifications
6. **Share Documentation** in markdown format

This workflow makes development **reproducible, collaborative, and AI-friendly**, whether you're writing in Word or a dedicated markdown editor.
