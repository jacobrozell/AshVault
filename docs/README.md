# GitHub Pages (legal & support)

Static pages for App Store **Privacy Policy URL**, **Support URL**, and **Accessibility URL**.

## Enable Pages (one-time)

1. Open [github.com/jacobrozell/AshVault/settings/pages](https://github.com/jacobrozell/AshVault/settings/pages)
2. **Build and deployment → Source:** Deploy from a branch
3. **Branch:** `main` · **Folder:** `/docs`
4. Save — site goes live in 1–3 minutes

## URLs (after Pages is enabled)

| Page | URL |
|------|-----|
| Home | `https://jacobrozell.github.io/AshVault/` |
| Privacy Policy | `https://jacobrozell.github.io/AshVault/privacy-policy.html` |
| Support | `https://jacobrozell.github.io/AshVault/support.html` |
| Accessibility | `https://jacobrozell.github.io/AshVault/accessibility.html` |

Use the **Privacy Policy** and **Support** URLs in App Store Connect. The **Accessibility** URL is linked from in-app Settings.

## Local preview

```bash
python3 -m http.server 8080 --directory docs
# http://localhost:8080/privacy-policy.html
```

## Updates

Edit the HTML files, commit, push — Pages redeploys automatically. Bump the "Last updated" date when practices change (especially Firebase telemetry).

Markdown sources for reference: [`accessibility.md`](accessibility.md) (detailed rollout plan), [`privacy-policy.md`](privacy-policy.md).
