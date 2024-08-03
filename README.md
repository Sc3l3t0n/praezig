# ⚡praezig⚡ - Markdown Presentation Tool

1. [What is praezig?](#what-is-praezig%3F)
2. [How to use praezig?](#how-to-use-praezig%3F)
3. [Installation](#installation)

## What is praezig?

- **praezig** is a simple terminal presentation tool written in **zig** for creating presentations using markdown syntax.
- It runs as a terminal application, allowing users to present directly from the command line.
- Lightweight and easy to use, **praezig** is perfect for quick and effective presentations.

### Name Origin

- The name **praezig** combines the German abbreviation **präsi** (short for presentation) and **zig**.

### Constraints

**praezig** is in early development and has some constraints:

#### Supported Platforms

- **praezig** is currently supported on Linux and Windows for most functionalities.

#### Coloring and Styling

- Coloring and styling only work with terminals that support ANSI escape codes.
- Some features may not work on all terminals.

## How to use praezig?

### Create a Markdown File

- **praezig** uses a single markdown file to create a presentation.
- Slides are separated by `---`.
- Use `#` for headings, `##` for subheadings, and `-` for bullet points.
- Empty lines are ignored.

```markdown
# Slide 1

Text

## Subheading 1

- Bullet 1

---

# Slide 2
```

### Run Presentation

To start the presentation, run the following command:

```bash
praezig relative-path-to-markdown-file

praezig ./example.md
```

### Keyboard Controls

Navigate through the slides using the following controls:

- **Right arrow**, **L**, or **Space**: Next slide
- **Left arrow** or **H**: Previous slide
- **Q**: Quit presentation

## Installation

### Manual Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Sc3l3t0n/praezig.git
   cd ./praezig
   ```

2. Build the project:

   ```bash
   zig build run -- path-to-markdown-file # Build and run
   # or
   zig build # Build release and take the binary from zig-out/bin
   ```

3. If you built the project, move the binary to a directory in your PATH.
