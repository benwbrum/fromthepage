import { Controller } from "@hotwired/stimulus"

// Detects Safari browser and shows helpful message about Avast antivirus issues
export default class extends Controller {
  static targets = ["banner"]

  connect() {
    if (this.isSafari() && this.shouldShowBanner()) {
      this.showCompatibilityBanner()
    }
  }

  isSafari() {
    const userAgent = navigator.userAgent.toLowerCase()
    return userAgent.includes('safari') && !userAgent.includes('chrome') && !userAgent.includes('chromium')
  }

  shouldShowBanner() {
    // Only show once per session to avoid being annoying
    return !sessionStorage.getItem('fromthepage_browser_banner_shown')
  }

  showCompatibilityBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.style.display = 'block'
      sessionStorage.setItem('fromthepage_browser_banner_shown', 'true')
    }
  }

  dismiss() {
    if (this.hasBannerTarget) {
      this.bannerTarget.style.display = 'none'
    }
  }
}