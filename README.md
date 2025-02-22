# MindScape: Decentralized Reflection Journal

MindScape is a decentralized platform built on the Stacks blockchain that enables users to securely store, manage, and share their personal reflections and insights. The platform emphasizes privacy and controlled disclosure, allowing users to determine how and when their reflections become visible to others.

## Features

### Core Functionality
- Create and store personal reflections with up to 2048 characters
- Set custom release dates for time-delayed sharing
- Add up to 10 themes per reflection for easy organization
- Toggle between restricted and public visibility
- Option for hidden reflections that are revealed at random intervals

### Privacy Controls
- **Restricted Mode**: Keep reflections private and accessible only to you
- **Hidden Mode**: Submit reflections to a shared space where they're revealed at randomized times
- **Release Dates**: Set future dates for when reflections become publicly accessible
- **Theme-based Discovery**: Find public reflections through thematic categorization

### Smart Contract Capabilities
- Secure storage of reflections on the blockchain
- Automated time-release mechanism
- Theme-based indexing system
- User-specific reflection counting
- Privacy state management

## Technical Details

### Data Structures

#### Reflection Storage
```clarity
{
    reflection-id: uint,
    creator: principal,
    insight: (string-utf8 2048),
    creation-date: uint,
    release-date: uint,
    is-restricted: bool,
    is-hidden: bool,
    themes: (list 10 (string-utf8 32))
}
```

#### Shared Space
```clarity
{
    reflection-id: uint,
    creator: principal,
    is-revealed: bool,
    reveal-block: uint
}
```

### Key Functions

#### Creating Reflections
```clarity
(create-reflection 
    (insight (string-utf8 2048)) 
    (release-date uint) 
    (is-restricted bool)
    (is-hidden bool)
    (themes (list 10 (string-utf8 32))))
```

#### Viewing Reflections
```clarity
(view-reflection (reflection-id uint) (creator principal))
```

#### Managing Visibility
```clarity
(update-visibility 
    (reflection-id uint) 
    (is-restricted bool)
    (is-hidden bool))
```

## Usage Guide

### Creating a New Reflection

1. Call the `create-reflection` function with:
   - Your reflection content (max 2048 characters)
   - Desired release date (in block height)
   - Privacy settings (restricted/hidden)
   - Relevant themes (up to 10)

Example:
```clarity
(contract-call? 
    .mindscape 
    create-reflection 
    "My personal insight..." 
    u100000 
    false 
    false 
    (list "growth" "learning"))
```

### Reading Reflections

To view a reflection, you need:
- The reflection ID
- The creator's principal

```clarity
(contract-call? 
    .mindscape 
    view-reflection 
    u1 
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Managing Themes

Add themes to help others discover your public reflections:
```clarity
(contract-call? 
    .mindscape 
    add-theme-to-directory 
    u1 
    "personal-growth")
```

## Error Codes

- `err-unauthorized` (u100): Access denied
- `err-invalid-reflection` (u101): Invalid reflection content
- `err-invalid-release-date` (u102): Invalid release date
- `err-reflection-not-found` (u103): Reflection doesn't exist
- `err-theme-limit` (u104): Theme index is full
- `err-invalid-theme` (u105): Invalid theme format
- `err-invalid-participant` (u106): User not found
- `err-not-in-shared-space` (u107): Reflection not in shared space
- `err-already-revealed` (u108): Reflection already revealed

## Contributing

MindScape is an open-source project and welcomes contributions. To contribute:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Security Considerations

- All reflections are stored on the public blockchain
- While restricted reflections are only accessible to their creators, the content exists on-chain
- Hidden reflections will eventually become public once revealed
- Consider the permanence of blockchain storage when creating reflections

## Future Development

Planned features and improvements:
- Enhanced theme discovery system
- Reflection interaction mechanics (reactions, comments)
- Advanced privacy controls
- Integration with decentralized storage for longer reflections
- Community curation mechanisms
