---
.title = "How to use praezig",
.colors = .{
    .decorations = .{
        .title = .green,
    },
    .text = .{
        .title = .cyan,
    }
},
---

# How to use praezig

Create terminal slides

Use one Markdown file

- Write slides in plain text
- Start the deck from your terminal
- Move through slides with the keyboard

---

# Quick start

Run a presentation file

- praezig ./EXAMPLE.md
- zig build run -- ./EXAMPLE.md
- praezig ./EXAMPLE.md
- Use a relative or absolute path

---

# One file per deck

praezig reads one Markdown file

- Each slide lives in the same file
- A line with --- starts a new slide
- Empty lines are ignored

---

# Basic slide syntax

These are the useful building blocks

- # creates a main heading
- ## creates a subheading
- - creates a bullet point
- Any other line becomes body text

---

# Example slide content

## Team update

This line is normal body text

- Progress looks good
- The next milestone is Friday
- Questions can wait for the end

---

# Add a title bar

Put frontmatter at the top

- Start with ---
- Add .title = "Your Title"
- Close the frontmatter with ---

---

# Minimal deck example

Copy this structure

- ---
- .title = "Demo"
- ---
- # First slide
- ---
- # Second slide

---

# Presenting live

The app opens in the terminal

- Use full-screen terminal space
- Keep lines short and readable
- Split longer topics across more slides

---

# Keyboard controls

Move through the deck

- Right arrow goes forward
- Space goes forward
- l goes forward
- Left arrow goes back
- h goes back
- q quits the presentation

---

# Current limits

Keep the format simple

- Use plain text, headings, and bullets
- Avoid very long lines
- Do not rely on advanced Markdown features

---

# Ready to try it

Create your own file next

- Copy this example
- Replace the text with your content
- Run praezig with your new file
