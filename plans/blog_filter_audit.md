# Blog Filter Button Audit - aibrainbuilders.com/blog/

## Context

Filter buttons on the blog index (All / Strategy / Guide / Data / Case Study) need to correctly show/hide cards. The JS is wired but has two real problems identified in audit.

---

## Audit Findings

### What works
- Selector `.post-grid > div[data-category]` is correct - outer wrappers are direct children of `.post-grid` with `data-category` attributes
- `card.dataset.category` values ("strategy", "data", "guide") match button `data-filter` values
- `display: none` on a CSS grid item removes it from flow - no ghost gaps
- AOS `once: true` + hide/show works fine - cards reappear without re-animating

### Bug 1 - "Case Study" filter returns empty grid, no feedback
- No posts have `data-category="case-study"`
- Clicking "Case Study" hides all 3 cards and shows a blank grid
- No message, no indication of zero results
- **Fix:** Remove "Case Study" button - it maps to no current posts and misleads visitors. When more posts are added with that category, add the button back.

### Bug 2 - No empty state when filter has zero matches
- If a filter matches nothing (case study, or any future filter mismatch), user sees blank page with no explanation
- **Fix:** Add a hidden empty-state div inside `.post-grid`. After each filter run, count visible cards - if 0, show it.

---

## Changes

**File:** `~/ai/projects/aibrainbuilders/blog/index.html`

### 1. Remove "Case Study" filter button
```html
<!-- DELETE this line -->
<button class="filter-btn" data-filter="case-study">Case Study</button>
```

### 2. Add empty state div inside `.post-grid` (after CARDS:END sentinel)
```html
<!-- CARDS:END -->
<div id="filter-empty" style="display:none; grid-column:1/-1; text-align:center; padding:60px 20px;">
  <p style="font-family:'JetBrains Mono',monospace; font-size:0.75rem; color:var(--text-3); text-transform:uppercase; letter-spacing:0.1em;">No posts in this category yet</p>
</div>
```

### 3. Update filter JS to show/hide empty state after each filter
```javascript
cards.forEach(function(card) {
  card.style.display = (f === 'all' || card.dataset.category === f) ? '' : 'none';
});
var visible = Array.from(cards).filter(function(c) { return c.style.display !== 'none'; }).length;
document.getElementById('filter-empty').style.display = visible === 0 ? '' : 'none';
```

---

## Verification

1. Deploy locally - open blog index in browser
2. Click each filter button: Strategy, Guide, Data → only matching cards visible
3. Click All → all 3 cards visible
4. Confirm no "Case Study" button present
5. Manually add `data-filter="test"` button temporarily, click it → empty state message appears
6. `cf-deploy update aibrainbuilders-blog` → verify live

---

## Critical File

- `~/ai/projects/aibrainbuilders/blog/index.html`
