-- Have an AI review each AUR package's build file changes before building.
--
-- For every AUR package base about to be built, the review script (in this
-- directory) sends the git diff since the last reviewed commit (AUR_SEEN)
-- together with package metadata to an AI model, which answers OK or
-- QUESTIONABLE. OK proceeds. QUESTIONABLE prints the justification, opens the
-- diff in a pager and asks for manual approval; declining aborts the install.
-- Any review failure also falls back to manual review.
--
-- The script takes over the diff menu's job, including advancing AUR_SEEN, so
-- the diff menu is disabled here.

yay.opt.diff_menu = false

-- gopher-lua reports the chunk source without the "@" prefix of PUC Lua.
local review_cmd = debug.getinfo(1, "S").source:match("^@?(.*)/[^/]*$") .. "/review"

-- AUR metadata is attacker-controlled; never interpolate it into a shell
-- command without quoting.
local function shquote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Maintainers are only exposed by UpgradeSelect; remember them for the review.
local maintainers = {}

yay.create_autocmd("UpgradeSelect", {
  desc = "record AUR maintainers for the AI review",
  callback = function(event)
    for _, pkg in ipairs(event.data.upgrades) do
      if pkg.repository == "aur" and pkg.maintainer ~= "" then
        maintainers[pkg.base] = pkg.maintainer
      end
    end
  end,
})

local function list(values)
  return table.concat(values, ", ")
end

local function context_text(event)
  local d = event.data
  local s = d.srcinfo
  local lines = {}
  local function add(fmt, ...) lines[#lines + 1] = string.format(fmt, ...) end

  local upgrade = false
  for _, pkg in ipairs(d.packages) do
    if pkg.upgrade then upgrade = true end
  end

  add("operation: %s", upgrade and "upgrade of installed AUR package" or "new install of AUR package")
  add("pkgbase: %s", d.base)
  add("maintainer: %s", maintainers[d.base] or "unknown")
  add("last_modified: %s", os.date("%Y-%m-%d %H:%M", d.last_modified))
  add("target_version: %s", d.version)
  add("pkgdesc: %s", s.pkgdesc)
  add("url: %s", s.url)
  add("license: %s", list(s.license))
  add("arch: %s", list(s.arch))
  add("depends: %s", list(s.depends))
  add("makedepends: %s", list(s.makedepends))
  add("provides: %s", list(s.provides))
  add("conflicts: %s", list(s.conflicts))
  add("replaces: %s", list(s.replaces))
  add("packages:")
  for _, pkg in ipairs(d.packages) do
    add("  - name: %s, local_version: %s, new_version: %s, reason: %s, devel: %s",
      pkg.name, pkg.local_version ~= "" and pkg.local_version or "not installed",
      pkg.version, pkg.reason, tostring(pkg.devel))
  end

  return table.concat(lines, "\n") .. "\n"
end

yay.create_autocmd("AURPreInstall", {
  desc = "AI review of PKGBUILD changes, manual review if questionable",
  callback = function(event)
    local base = event.match
    local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or event.data.dir
    local ctx_path = runtime_dir .. "/yay-ai-review-" .. base .. ".txt"

    local f = assert(io.open(ctx_path, "w"))
    f:write(context_text(event))
    f:close()

    local rc = os.execute(table.concat({
      shquote(review_cmd), shquote(event.data.dir), shquote(base), shquote(ctx_path),
    }, " "))
    os.remove(ctx_path)

    if rc ~= 0 then
      yay.abort(base .. ": build file changes rejected")
    end
  end,
})
