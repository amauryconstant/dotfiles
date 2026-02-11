# Merge Request Special Cases

This file contains guidance for special merge request scenarios.

## WIP / Draft MRs

When creating work-in-progress merge requests, include `[WIP]` prefix in summary and show remaining tasks.

**Template**:
```markdown
### Summary
[WIP] Add OAuth2 authentication support

### Changes
- [ ] OAuth2 provider configuration
- [ ] Token refresh logic
- [ ] Error handling

### Status
Work in progress - token refresh logic needs testing
```

**Guidelines**:
- Use `[WIP]` prefix in summary line
- Mark incomplete tasks with `- [ ]`
- Add "Status" section explaining what's pending
- Keep description focused on overall goal, not implementation details

## Backports

When backporting changes from main to release branches, clearly indicate the backport nature.

**Template**:
```markdown
### Summary
Backport: Fix authentication token expiration

### Changes
- Backport commit abc123 from main to release-1.2
- Applies same fix for token expiration

### Testing
Same as original fix in main

### Related Issues
Backports #456 from main
```

**Guidelines**:
- Use "Backport:" prefix in summary
- Specify source commit hash
- Reference original issue/PR
- Testing section can refer to original testing

## Breaking Changes

When changes introduce breaking changes, document them clearly with migration instructions.

**Template**:
```markdown
### Summary
Refactor configuration format to domain-specific schema

### Changes
- Migrate to domain-specific configuration format
- Remove legacy config support
- Update documentation

### Breaking Changes
Old configuration format no longer supported. Run migration script:
`bin/migrate-config --from-legacy`

See `MIGRATION.md` for details.
```

**Guidelines**:
- Always use "Breaking Changes" section
- Provide clear migration instructions
- Reference additional documentation if needed
- Consider whether backport is needed

## Multiple Related Features

When MR includes multiple related features, group them logically.

**Template**:
```markdown
### Summary
Add OAuth2 authentication and user profile management

### Changes
**Authentication**
- Add OAuth2 provider configuration
- Implement token refresh logic
- Add error handling for failed authentications

**User Profiles**
- Add user profile CRUD endpoints
- Implement profile avatar upload
- Add profile visibility settings

### Testing
1. Test OAuth2 login flow
2. Test token refresh
3. Test profile creation and updates
4. Test avatar upload
5. Test profile visibility settings
```

**Guidelines**:
- Use subheadings under "Changes" to group related work
- Keep each section focused and concise
- Ensure testing covers all groups

## Security Fixes

When MR addresses security vulnerabilities, be thorough in documenting the fix.

**Template**:
```markdown
### Summary
Fix XSS vulnerability in user input handling

### Changes
- Sanitize all user input before rendering
- Add Content-Security-Policy headers
- Update to latest dependency versions

### Testing
1. Attempt XSS injection in all input fields
2. Verify CSP headers are present
3. Test with automated security scanner

### Security
Addresses CVE-2024-12345
See SECURITY.md for full disclosure
```

**Guidelines**:
- Clearly state security issue type
- Include CVE if applicable
- Reference security documentation
- Provide thorough testing guidance

## Performance Improvements

When MR focuses on performance, include before/after metrics.

**Template**:
```markdown
### Summary
Optimize database queries for faster page loads

### Changes
- Add database indexes on frequently queried columns
- Implement query result caching
- Optimize N+1 query pattern

### Testing
1. Verify functionality remains unchanged
2. Measure page load times:
   - Before: 2.5s average
   - After: 0.8s average (3x improvement)

### Performance
- Page load: 2.5s → 0.8s (3x faster)
- Database queries: 45 → 12 per page load
- Cache hit rate: 78%
```

**Guidelines**:
- Include before/after metrics
- Use specific numbers where possible
- Verify functionality is unchanged
- Document caching behavior
