# Merge Request Examples

This file contains detailed output examples for merge requests.

## Simple Feature MR

```markdown
**Title**: Add OAuth2 authentication support

```markdown
### Summary
Add OAuth2 authentication support for user login and token management.

### Changes
- Add OAuth2 provider configuration
- Implement token refresh logic
- Add error handling for failed authentications

### Testing
1. Configure OAuth2 provider credentials
2. Try logging in with OAuth2
3. Verify token refresh works after expiry
```
```

## Bugfix MR with Context

```markdown
**Title**: Fix session restore hanging on notification daemon timeouts

```markdown
### Summary
Fix session restore hanging indefinitely when notification daemon calls timeout.

### Changes
- Add timeout handling for notification daemon calls
- Log timeout events to journal
- Gracefully continue restore if notifications fail

### Testing
1. Start a session, logout, then restore
2. Verify restore completes even if notification daemon is slow
3. Check journal logs for timeout events
```
```

## Large Refactor MR

```markdown
**Title**: Refactor theme system with semantic variables for consistency across 13 apps

```markdown
### Summary
Refactor theme system with semantic variables to ensure consistent color usage across all applications.

### Changes
- Define 24 semantic color variables (backgrounds, foregrounds, accents)
- Update all 8 theme variants with semantic mappings
- Migrate 13 apps to use semantic variables
  - Desktop: Waybar, Dunst, Wofi, Wlogout, Hyprland, Ghostty, Hyprlock
  - CLI: bat, broot, btop, lazygit, starship, yazi
- Add theme switching CLI: `theme switch <name>`

### Testing
1. Switch between themes with `theme switch <name>`
2. Verify all 13 apps use correct colors
3. Test darkman automatic switching

### Breaking Changes
Existing custom theme configs may need migration. See `themes/MIGRATION.md` for details.

### Related Issues
Closes #123, #456
```
```

## Simple Bugfix MR

```markdown
**Title**: Fix authentication token expiration

```markdown
### Summary
Fix authentication tokens expiring prematurely due to incorrect timestamp validation.

### Changes
- Fix token expiration timestamp calculation
- Add unit tests for token validation

### Testing
1. Login and verify token works for full duration
2. Run unit tests
```
```

## Documentation Update MR

```markdown
**Title**: Update API documentation with new endpoints

```markdown
### Summary
Update API documentation to reflect recently added endpoints and clarify authentication flow.

### Changes
- Document new `GET /api/v2/users` endpoint
- Document new `POST /api/v2/auth/refresh` endpoint
- Clarify authentication flow with examples
- Add request/response examples for all endpoints

### Testing
Review documentation in browser, verify all examples are correct
```
```
