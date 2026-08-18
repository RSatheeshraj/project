const { By, Key } = require('selenium-webdriver');
const WaitUtils = require('../utils/waitUtils');

class LoginPage {
  constructor(driver) {
    this.driver = driver;
    this.waitUtils = new WaitUtils(driver);
    this.emailInput = By.css('#login-email, input[type="email"]');
    this.passwordInput = By.css('#login-password, input[type="password"]');
    this.submitButton = By.css('button[type="submit"]');
    this.errorMessage = By.css('div[style*="183,28,28"], p.text-red-400, .error-message, [role="alert"]');
    this.registerLink = By.css('a[href="/register"]');
  }

  async navigate(baseUrl) {
    await this.driver.get(`${baseUrl}/login`);
    await this.waitUtils.waitForDocumentReady();
  }

  async login(email, password) {
    const emailEl = await this.waitUtils.waitForElementVisible(this.emailInput, 10000);
    await emailEl.sendKeys(Key.CONTROL, 'a');
    await emailEl.sendKeys(Key.BACK_SPACE);
    if (email) {
      await emailEl.sendKeys(email);
    }

    const passEl = await this.waitUtils.waitForElementVisible(this.passwordInput, 10000);
    await passEl.sendKeys(Key.CONTROL, 'a');
    await passEl.sendKeys(Key.BACK_SPACE);
    if (password) {
      await passEl.sendKeys(password);
    }

    const btn = await this.driver.findElement(this.submitButton);
    await btn.click();
  }

  async getErrorMessage() {
    try {
      const errEl = await this.waitUtils.waitForElementVisible(this.errorMessage, 5000);
      return await errEl.getText();
    } catch (e) {
      return null;
    }
  }
}

module.exports = LoginPage;
