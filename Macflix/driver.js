const qs = (...args) => document.querySelector(...args)
const qsa = (...args) => document.querySelectorAll(...args)

window.netflix = mountDriver()

function mountDriver() {
    // Makes necessary changes to the DOM and then returns functions that depend on those mutations
    // to drive Netflix.

    // INTERCEPT CONSOLE.LOG

    const oldLog = console.log
    console.log = (...args) => {
        const message = args.map((x) => String(x)).join(' ')
        window.webkit.messageHandlers.onConsoleLog.postMessage(message)
        oldLog.apply(console, args)
    }

    // REMOVE STICKY HEADER

    // Nuke the fixed header since we're likely using a small viewport.
    const stickyHeaderObserver = new MutationObserver((muts) => {
        for (const mut of muts) {
            const header = mut.target
            if (header.style.position === 'fixed') {
                header.style.position = 'relative'
            }
        }
    })
    stickyHeaderObserver.observe(qs('.pinning-header-container'), {
        attributeFilter: ['style'],
        attributes: true,
    })

    // Walks entirety of an html node's downstream tree and
    // returns Set of <video> nodes it finds.
    //
    // root is node | null
    // found is Set of matching nodes
    function crawlNode(root, found = new Set()) {
        const predicate = (node) => node && node.tagName === 'VIDEO'
        if (!root || !root.childNodes) {
            return found
        }
        if (predicate(root)) {
            found.add(root)
        }
        return Array.from(root.childNodes).reduce((acc, node) => {
            if (predicate(node)) {
                return crawlNode(node, new Set([...acc, node]))
            } else {
                return crawlNode(node, acc)
            }
        }, found)
    }

    // This version takes an array of nodes
    function crawlNodes(roots) {
        return Array.from(roots).reduce((acc, node) => crawlNode(node, acc), new Set())
    }

    // mutation observer handler that walks all addedNodes + children looking
    // for added <video>s.
    //
    // FIXME: adds listeners to <video>s but never removes them.
    function videoFinder(muts) {
        for (const mut of muts) {
            const videos = crawlNodes(mut.addedNodes)
            if (location.pathname.startsWith('/watch/')) {
                // If we are watching a show, get the dimensions of the video when it loads.
                for (const video of videos) {
                    if (video.readyState === HTMLMediaElement.HAVE_NOTHING) {
                        // FIXME: mem leak
                        video.addEventListener('loadedmetadata', (e) => {
                            const { videoWidth: width, videoHeight: height } = video
                            onPrimaryVideoFound({ width, height })
                        })
                    } else {
                        const { videoWidth: width, videoHeight: height } = video
                        onPrimaryVideoFound({ width, height })
                    }
                }
            } else {
                // We aren't watching a show, so autopause all videos as they spawn.
                for (const video of videos) {
                    video.pause()
                }
            }
        }
    }
    const observer = new MutationObserver(videoFinder)
    observer.observe(document.body, {
        attributes: false,
        childList: true,
        characterData: false,
        subtree: true,
    })

    ////////////////////////////////////////////////////////////

    // dims is { width, height } or null
    function onPrimaryVideoFound(dims) {
        console.log('onPrimaryVideoFound', dims)
        window.webkit.messageHandlers.onVideoDimensions.postMessage(dims)
    }

    function handleUrlChange(path) {
        const message = { url: path }
        window.webkit.messageHandlers.onPushState.postMessage(message)
        if (!path.startsWith('/watch/')) {
            // clear aspect ratio when we aren't in /watch
            onPrimaryVideoFound(null)
        }
    }

    // STYLE MOUNT POINTS
    // TODO: Clean up

    const style = document.createElement('style')
    style.id = 'foo'
    document.head.appendChild(style)

    const style2 = document.createElement('style')
    style2.id = 'foo2'
    document.head.appendChild(style2)

    // Handle fullscreen click
    document.addEventListener(
        'click',
        (e) => {
            if (e.target.classList.contains('button-nfplayerFullscreen')) {
                e.preventDefault()
                e.stopPropagation()
                window.webkit.messageHandlers.requestFullscreen.postMessage(null)
            }
        },
        true
    )

    // DETECT URL CHANGE

    // TODO: clean up. i got superstitious and added a redundant handler.
    history.onpopstate = () => {
        const message = { url: location.pathname }
        handleUrlChange(location.pathname)
    }

    window.onpopstate = () => {
        const message = { url: location.pathname }
        handleUrlChange(location.pathname)
    }

    const pushState = history.pushState
    history.pushState = (...args) => {
        const [state, title, url] = args
        if (typeof history.onpushstate === 'function') {
            history.onpushstate(...args)
        }
        handleUrlChange(url)
        return pushState.apply(history, args)
    }

    return {
        adjustPlaybackSpeed(delta) {
            if (!location.pathname.startsWith('/watch/')) return
            const video = qs('video')
            if (!video) return
            video.playbackRate += delta
        },
        nextEpidode() {
            const button = qs('.button-nfplayerNextEpisode')
            if (button) button.click()
        },
        bumpForward() {
            const button = qs('.button-nfplayerFastForward')
            if (button) button.click()
        },
        bumpBackward() {
            const button = qs('.button-nfplayerBackTen')
            if (button) button.click()
        },
        playVideo() {
            const button = qs('.button-nfplayerPlay')
            if (button) button.click()
        },
        pauseVideo() {
            const button = qs('.button-nfplayerPause')
            if (button) button.click()
        },
        fullscreenVideo() {
            const button = document.querySelector('.button-nfplayerFullscreen')
            if (button) button.click()
        },
        toggleVideoPlayback() {
            const button = qs('.button-nfplayerPlay') || qs('.button-nfplayerPause')
            if (button) button.click()
        },
        toggleSubtitleVisibility(isVisible) {
            const style = qs('#foo2')
            style.innerHTML = `
            .player-timedtext-text-container {
                display: ${isVisible ? 'block' : 'none'} !important;
            }
            `
        },
        setSubSize(pixels) {
            const style = qs('#foo')
            style.innerHTML = `
            .player-timedtext-text-container span[style] {
                font-size: ${pixels}px !important;
            }
            `
        },
    }
}
