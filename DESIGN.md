# Dockside Design Document

## Purpose
A focused tool to assist in Dockerizing Ruby projects, particularly:
- Ruby on Rails applications
- Ansible-based projects
- Bash script collections

## Design Philosophy
- Pragmatic: Focus on real-world package dependencies rather than theoretical completeness
- Conservative: Favor detecting too many dependencies over missing critical ones
- Unobtrusive: Analyze without requiring project modifications
- Efficient: Quick analysis with meaningful, actionable output

## Key Features
1. Dependency Analysis
   - Parse Gemfile.lock for native extension requirements
   - Scan Ruby source for system commands
   - Map gems to their system package dependencies
   - Handle development vs production package separation

2. Docker Best Practices
   - Multi-stage builds
   - Proper base/build/development package separation
   - Minimal image sizes
   - Security considerations

3. Project-Specific Intelligence
   - Rails-specific package requirements
   - Ansible tooling dependencies
   - Common development tools

## Implementation Notes
- Pure Ruby implementation
- Minimal dependencies
- Conservative package detection
- Clear, actionable output
- Focus on Ubuntu/Debian packages

## Scope Limitations
- Targets Ubuntu/Debian-based images
- Focuses on Ruby ecosystem
- Personal tool, optimized for known use cases
