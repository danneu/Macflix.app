const qs = (...args) => document.querySelector(...args)
const qsa = (...args) => document.querySelectorAll(...args)

window.netflix = mountDriver()

function mountDriver() {
  // Makes necessary changes to the DOM and then returns functions that depend on those mutations
  // to drive Netflix.

  // INTERCEPT CONSOLE.LOG

  const oldLog = console.log
  console.log = (...args) => {
    const message = args.map(x => String(x)).join(" ")
    window.webkit.messageHandlers.onConsoleLog.postMessage(message)
    oldLog.apply(console, args)
  }

  // STYLE MOUNT POINTS
  // TODO: Clean up

  const style = document.createElement("style")
  style.id = "foo"
  document.head.appendChild(style)

  const style2 = document.createElement("style")
  style2.id = "foo2"
  document.head.appendChild(style2)

  // Handle fullscreen click
  document.addEventListener(
    "click",
    e => {
      if (e.target.classList.contains("button-nfplayerFullscreen")) {
        e.preventDefault()
        e.stopPropagation()
        window.webkit.messageHandlers.requestFullscreen.postMessage()
      }
    },
    true
  )

  // DETECT URL CHANGE

  history.onpopstate = () => {
    const message = { url: location.pathname }
    window.webkit.messageHandlers.onPushState.postMessage(message)
  }

  const pushState = history.pushState
  history.pushState = (...args) => {
    const [state, title, url] = args
    if (typeof history.onpushstate === "function") {
      history.onpushstate(...args)
    }
    const message = {
      url
    }
    window.webkit.messageHandlers.onPushState.postMessage(message)
    return pushState.apply(history, args)
  }

  return {
    nextEpidode() {
      const button = qs(".button-nfplayerNextEpisode")
      if (button) button.click()
    },
    bumpForward() {
      const button = qs(".button-nfplayerFastForward")
      if (button) button.click()
    },
    bumpBackward() {
      const button = qs(".button-nfplayerBackTen")
      if (button) button.click()
    },
    playVideo() {
      const button = qs(".button-nfplayerPlay")
      if (button) button.click()
    },
    pauseVideo() {
      const button = qs(".button-nfplayerPause")
      if (button) button.click()
    },
    fullscreenVideo() {
      const button = document.querySelector(".button-nfplayerFullscreen")
      if (button) button.click()
    },
    toggleVideoPlayback() {
      const button = qs(".button-nfplayerPlay") || qs(".button-nfplayerPause")
      if (button) button.click()
    },
    toggleSubtitleVisibility(isVisible) {
      const style = qs("#foo2")
      style.innerHTML = `
            .player-timedtext-text-container {
                display: ${isVisible ? "block" : "none"} !important;
            }
            `
    },
    setSubSize(pixels) {
      const style = qs("#foo")
      style.innerHTML = `
            .player-timedtext-text-container span[style] {
                font-size: ${pixels}px !important;
            }
            `
    }
  }
}
