const { until, By } = require('selenium-webdriver');

class WaitUtils {
  constructor(driver) {
    this.driver = driver;
  }

  async waitForElementVisible(locator, timeout = 10000) {
    if (!this.driver) return null;
    return await this.driver.wait(until.elementLocated(locator), timeout)
      .then(element => this.driver.wait(until.elementIsVisible(element), timeout));
  }

  async waitForUrlContains(urlSubstring, timeout = 10000) {
    if (!this.driver) return false;
    return await this.driver.wait(until.urlContains(urlSubstring), timeout);
  }

  async waitForTitle(titleSubstring, timeout = 10000) {
    if (!this.driver) return false;
    return await this.driver.wait(until.titleContains(titleSubstring), timeout);
  }

  async waitForDocumentReady(timeout = 10000) {
    if (!this.driver) return false;
    return await this.driver.wait(async () => {
      const state = await this.driver.executeScript('return document.readyState');
      return state === 'complete';
    }, timeout);
  }
}

module.exports = WaitUtils;
