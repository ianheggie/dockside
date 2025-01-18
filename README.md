# Dockside

## Overview

Dockside is designed to simplify and optimize the Dockerization process for Ruby projects.
It analyzes system dependencies, package requirements, and suggests optimum Docker best practices.
It is focused on what I needed, rather than being an all-purpose tool, but hopefully will be of use to some.

## Document Purposes

- **README.md**: A user-friendly guide for humans, explaining project setup, usage, and contribution guidelines.
- **GUIDELINES.md**: A comprehensive design philosophy and technical reference, serving as both a development manifesto
  and an AI collaboration framework.

## Features

- Automatic system command dependency detection
- Package requirement analysis
- Docker multi-stage build recommendations
- Support for Ruby on Rails, Ansible, and Bash script projects

## Installation

### Gem Installation

Add to your project's Gemfile:

```ruby
gem 'dockside', github: 'ianheggie/dockside'
```

Then install dependencies:

```bash
bundle install
```

### Manual Installation

```bash
git clone https://github.com/ianheggie/dockside.git
cd dockside
bundle install
bundle exec rake install
```

## Usage

Analyze a Ruby project's Dockerization potential:

```bash
dockside /path/to/ruby/project
```

## Development

### Setup

```bash
bin/setup
```

### Running Tests

```bash
rake test
```

### Interactive Console

```bash
bin/console
```

## Contributing

- Pull requests are welcome
- Contributions evaluated against project goals
- Focus on practical, actionable improvements

## License

MIT License - Free for personal and commercial use
