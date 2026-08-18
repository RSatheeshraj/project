const { until, By } = require('selenium-webdriver');

class WaitUtils {
  constructor(driver) {
    this.driver = driver;
  }

  async waitForUrlContains(substring, timeoutMs = 10000) {
    return await this.driver.wait(until.urlContains(substring), timeoutMs);
  }

  async waitForElementVisible(locator, timeoutMs = 10000) {
    const element = await this.driver.wait(until.elementLocated(locator), timeoutMs);
    await this.driver.wait(until.elementIsVisible(element), timeoutMs);
    return element;
  }

  async waitForElementLocated(locator, timeoutMs = 10000) {
    return await this.driver.wait(until.elementLocated(locator), timeoutMs);
  }

  async waitForTitle(substring, timeoutMs = 10000) {
    return await this.driver.wait(until.titleContains(substring), timeoutMs);
  }

  async waitForDocumentReady(timeoutMs = 10000) {
    return await this.driver.wait(async () => {
      const readyState = await this.driver.executeScript('return document.readyState');
      return readyState === 'complete';
    }, timeoutMs);
  }
}

module.exports = WaitUtils;
