((cssText, artDataUrl, profile) => {
  const STATE_KEY = "__CODEX_DREAM_SKIN_STATE__";
  const STYLE_ID = "codex-dream-skin-style";
  const CHROME_ID = "codex-dream-skin-chrome";
  const profileValues = {
    title: profile?.brand?.title || "Codex Dream Skin",
    subtitle: profile?.brand?.subtitle || "Custom theme",
    overlay: profile?.art?.overlay || "rgba(3, 9, 17, .68)",
    artPosition: profile?.art?.position || "-100% center",
    artSize: profile?.art?.size || "cover",
    composerBackground: profile?.composer?.background || "rgba(8, 19, 33, .80)",
    composerBorderColor: profile?.composer?.borderColor || "rgba(112, 145, 177, .38)",
    composerOutlineColor: profile?.composer?.outlineColor || "rgba(112, 145, 177, .28)",
    profileCardPadding: profile?.profileCards?.padding || "12px",
    homeBrandTop: profile?.home?.brandTop || "5px",
    homeBrandTitleLineHeight: profile?.home?.brandTitleLineHeight || "1.2",
    homeBrandSubtitleMarginTop: profile?.home?.brandSubtitleMarginTop || "1px",
    homeBrandSubtitleLineHeight: profile?.home?.brandSubtitleLineHeight || "1.2",
    homeWelcomePanelBackground: profile?.home?.welcomePanel?.background || "transparent",
    homeWelcomePanelBorder: profile?.home?.welcomePanel?.border || "0",
    homeWelcomePanelRadius: profile?.home?.welcomePanel?.radius || "0",
    homeWelcomePanelShadow: profile?.home?.welcomePanel?.shadow || "none",
    homeWelcomePanelOverflow: profile?.home?.welcomePanel?.overflow || "visible",
    homeSuggestionsBackground: profile?.home?.suggestions?.background || "rgba(8, 19, 33, .52)",
    homeSuggestionsBorderColor: profile?.home?.suggestions?.borderColor || "rgba(153, 183, 218, .24)",
    homeSuggestionsTextColor: profile?.home?.suggestions?.textColor || "#dce8f6",
    homeSuggestionsShadow: profile?.home?.suggestions?.shadow || "none",
    homeSuggestionsHoverBackground: profile?.home?.suggestions?.hoverBackground || "rgba(28, 51, 76, .70)",
    homeSuggestionsHoverBorderColor: profile?.home?.suggestions?.hoverBorderColor || "rgba(214, 173, 104, .55)",
    sidebarNewTaskInnerBackground: profile?.sidebar?.newTask?.innerBackground || "transparent",
    sidebarNewTaskInnerShadow: profile?.sidebar?.newTask?.innerShadow || "none",
    sendButtonBackground: profile?.actions?.send?.background || "linear-gradient(145deg, #7095c0, #476d98)",
    pauseButtonBackground: profile?.actions?.pause?.background || "rgba(92, 132, 176, .20)",
    pauseButtonBorderColor: profile?.actions?.pause?.borderColor || "rgba(139, 180, 220, .42)",
    pauseButtonColor: profile?.actions?.pause?.color || "#d6e7f7",
  };
  const escapeHtml = (value) => String(value).replace(/[&<>\"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;",
  })[character]);
  window.__CODEX_DREAM_SKIN_DISABLED__ = false;

  const previous = window[STATE_KEY];
  if (previous?.observer) previous.observer.disconnect();
  if (previous?.timer) clearInterval(previous.timer);
  if (previous?.scheduler?.timeout) clearTimeout(previous.scheduler.timeout);
  const artUrl = previous?.artUrl || (() => {
    const comma = artDataUrl.indexOf(",");
    const binary = atob(artDataUrl.slice(comma + 1));
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index);
    return URL.createObjectURL(new Blob([bytes], { type: "image/png" }));
  })();
  const existingStyle = document.getElementById(STYLE_ID);
  if (existingStyle) {
    existingStyle.textContent = cssText;
    existingStyle.dataset.dreamVersion = "4.6";
  }

  const clearSkinDom = () => {
    document.documentElement?.classList.remove("codex-dream-skin");
    document.documentElement?.style.removeProperty("--dream-art");
    document.documentElement?.style.removeProperty("--dream-overlay");
    document.documentElement?.style.removeProperty("--dream-art-position");
    document.documentElement?.style.removeProperty("--dream-art-size");
    document.documentElement?.style.removeProperty("--dream-composer-background");
    document.documentElement?.style.removeProperty("--dream-composer-border-color");
    document.documentElement?.style.removeProperty("--dream-composer-outline-color");
    document.documentElement?.style.removeProperty("--dream-profile-card-padding");
    document.documentElement?.style.removeProperty("--dream-home-brand-top");
    document.documentElement?.style.removeProperty("--dream-home-brand-title-line-height");
    document.documentElement?.style.removeProperty("--dream-home-brand-subtitle-margin-top");
    document.documentElement?.style.removeProperty("--dream-home-brand-subtitle-line-height");
    document.documentElement?.style.removeProperty("--dream-home-welcome-panel-background");
    document.documentElement?.style.removeProperty("--dream-home-welcome-panel-border");
    document.documentElement?.style.removeProperty("--dream-home-welcome-panel-radius");
    document.documentElement?.style.removeProperty("--dream-home-welcome-panel-shadow");
    document.documentElement?.style.removeProperty("--dream-home-welcome-panel-overflow");
    document.documentElement?.style.removeProperty("--dream-home-suggestions-background");
    document.documentElement?.style.removeProperty("--dream-home-suggestions-border-color");
    document.documentElement?.style.removeProperty("--dream-home-suggestions-text-color");
    document.documentElement?.style.removeProperty("--dream-home-suggestions-shadow");
    document.documentElement?.style.removeProperty("--dream-home-suggestions-hover-background");
    document.documentElement?.style.removeProperty("--dream-home-suggestions-hover-border-color");
    document.documentElement?.style.removeProperty("--dream-sidebar-new-task-inner-background");
    document.documentElement?.style.removeProperty("--dream-sidebar-new-task-inner-shadow");
    document.documentElement?.style.removeProperty("--dream-send-button-background");
    document.documentElement?.style.removeProperty("--dream-pause-button-background");
    document.documentElement?.style.removeProperty("--dream-pause-button-border-color");
    document.documentElement?.style.removeProperty("--dream-pause-button-color");
    document.querySelectorAll(".dream-home").forEach((node) => node.classList.remove("dream-home"));
    document.querySelectorAll(".dream-home-shell").forEach((node) => node.classList.remove("dream-home-shell"));
    document.getElementById(STYLE_ID)?.remove();
    document.getElementById(CHROME_ID)?.remove();
  };

  const ensure = () => {
    if (window.__CODEX_DREAM_SKIN_DISABLED__) return;
    const root = document.documentElement;
    if (!root || !document.body) return;

    const shellMain = document.querySelector("main.main-surface");
    const shellSidebar = document.querySelector("aside.app-shell-left-panel");
    if (!shellMain || !shellSidebar) {
      clearSkinDom();
      return;
    }

    root.classList.add("codex-dream-skin");
    root.style.setProperty("--dream-art", `url("${artUrl}")`);
    root.style.setProperty("--dream-overlay", profileValues.overlay);
    root.style.setProperty("--dream-art-position", profileValues.artPosition);
    root.style.setProperty("--dream-art-size", profileValues.artSize);
    root.style.setProperty("--dream-composer-background", profileValues.composerBackground);
    root.style.setProperty("--dream-composer-border-color", profileValues.composerBorderColor);
    root.style.setProperty("--dream-composer-outline-color", profileValues.composerOutlineColor);
    root.style.setProperty("--dream-profile-card-padding", profileValues.profileCardPadding);
    root.style.setProperty("--dream-home-brand-top", profileValues.homeBrandTop);
    root.style.setProperty("--dream-home-brand-title-line-height", profileValues.homeBrandTitleLineHeight);
    root.style.setProperty("--dream-home-brand-subtitle-margin-top", profileValues.homeBrandSubtitleMarginTop);
    root.style.setProperty("--dream-home-brand-subtitle-line-height", profileValues.homeBrandSubtitleLineHeight);
    root.style.setProperty("--dream-home-welcome-panel-background", profileValues.homeWelcomePanelBackground);
    root.style.setProperty("--dream-home-welcome-panel-border", profileValues.homeWelcomePanelBorder);
    root.style.setProperty("--dream-home-welcome-panel-radius", profileValues.homeWelcomePanelRadius);
    root.style.setProperty("--dream-home-welcome-panel-shadow", profileValues.homeWelcomePanelShadow);
    root.style.setProperty("--dream-home-welcome-panel-overflow", profileValues.homeWelcomePanelOverflow);
    root.style.setProperty("--dream-home-suggestions-background", profileValues.homeSuggestionsBackground);
    root.style.setProperty("--dream-home-suggestions-border-color", profileValues.homeSuggestionsBorderColor);
    root.style.setProperty("--dream-home-suggestions-text-color", profileValues.homeSuggestionsTextColor);
    root.style.setProperty("--dream-home-suggestions-shadow", profileValues.homeSuggestionsShadow);
    root.style.setProperty("--dream-home-suggestions-hover-background", profileValues.homeSuggestionsHoverBackground);
    root.style.setProperty("--dream-home-suggestions-hover-border-color", profileValues.homeSuggestionsHoverBorderColor);
    root.style.setProperty("--dream-sidebar-new-task-inner-background", profileValues.sidebarNewTaskInnerBackground);
    root.style.setProperty("--dream-sidebar-new-task-inner-shadow", profileValues.sidebarNewTaskInnerShadow);
    root.style.setProperty("--dream-send-button-background", profileValues.sendButtonBackground);
    root.style.setProperty("--dream-pause-button-background", profileValues.pauseButtonBackground);
    root.style.setProperty("--dream-pause-button-border-color", profileValues.pauseButtonBorderColor);
    root.style.setProperty("--dream-pause-button-color", profileValues.pauseButtonColor);

    let style = document.getElementById(STYLE_ID);
    if (!style) {
      style = document.createElement("style");
      style.id = STYLE_ID;
      (document.head || root).appendChild(style);
    }
    if (style.dataset.dreamVersion !== "4.6") {
      style.textContent = cssText;
      style.dataset.dreamVersion = "4.6";
    }

    const home = document.querySelector('[role="main"]:has([data-testid="home-icon"])');
    for (const candidate of document.querySelectorAll('[role="main"].dream-home')) {
      if (candidate !== home) candidate.classList.remove("dream-home");
    }
    if (home) home.classList.add("dream-home");

    shellMain.classList.toggle("dream-home-shell", Boolean(home));
    let chrome = document.getElementById(CHROME_ID);
    if (!chrome || chrome.parentElement !== document.body) {
      chrome?.remove();
      chrome = document.createElement("div");
      chrome.id = CHROME_ID;
      chrome.setAttribute("aria-hidden", "true");
      chrome.innerHTML = `
        <div class="dream-brand"><span class="dream-note">☾</span><span><b>${escapeHtml(profileValues.title)}</b><small>${escapeHtml(profileValues.subtitle)}</small></span></div>
        <div class="dream-signature">Moonlit Codex</div>`;
      document.body.appendChild(chrome);
    }
    const shellBox = shellMain.getBoundingClientRect();
    chrome.style.left = `${Math.round(shellBox.left)}px`;
    chrome.style.top = `${Math.round(shellBox.top)}px`;
    chrome.style.width = `${Math.round(shellBox.width)}px`;
    chrome.style.height = `${Math.round(shellBox.height)}px`;
    chrome.classList.toggle("dream-home-shell", Boolean(home));
  };

  const cleanup = () => {
    window.__CODEX_DREAM_SKIN_DISABLED__ = true;
    clearSkinDom();
    const state = window[STATE_KEY];
    state?.observer?.disconnect();
    if (state?.timer) clearInterval(state.timer);
    if (state?.scheduler?.timeout) clearTimeout(state.scheduler.timeout);
    if (state?.artUrl) URL.revokeObjectURL(state.artUrl);
    delete window[STATE_KEY];
    return true;
  };

  const scheduler = { timeout: null };
  const scheduleEnsure = () => {
    if (scheduler.timeout) clearTimeout(scheduler.timeout);
    scheduler.timeout = setTimeout(() => {
      scheduler.timeout = null;
      ensure();
    }, 180);
  };
  const observer = new MutationObserver(scheduleEnsure);
  observer.observe(document.documentElement, { childList: true, subtree: true });
  const timer = setInterval(ensure, 5000);
  window[STATE_KEY] = { ensure, cleanup, observer, timer, scheduler, artUrl, version: "4.6.0" };
  ensure();
  return { installed: true, version: "4.6.0" };
})(__DREAM_CSS_JSON__, __DREAM_ART_JSON__, __DREAM_PROFILE_JSON__)
