# Deployment Notes

Repository name used by the workflow:

```text
local-proxy-pool-subscription
```

The workflow publishes `public/` through GitHub Pages.

If Pages does not appear after the first run:

1. Open repository Settings.
2. Go to Pages.
3. Set Source to GitHub Actions.
4. Re-run `Update proxy subscription`.

The static files in `public/` are committed so the raw GitHub URLs work even before Pages deploys.

