const { By, until } = require('selenium-webdriver');

class DashboardPage {
  constructor(driver) {
    this.driver = driver;
    this.navHome = By.css('a[href="/home"]');
    this.navFarms = By.css('a[href="/farms"]');
    this.navSales = By.css('a[href="/sales"]');
    this.navReminders = By.css('a[href="/reminders"]');
    this.navScan = By.css('a[href="/scan"]');
    this.navHistory = By.css('a[href="/history"]');
    this.navProfile = By.css('a[href="/profile"]');
    this.navSettings = By.css('a[href="/settings"]');
    this.navDirectory = By.css('a[href="/directory"]');
    this.userMenuButton = By.css('[aria-label="User Menu"], button.profile-btn');
    this.signOutButton = By.xpath("//button[contains(text(), 'Sign Out') or contains(text(), 'Logout')]");
  }

  async isLoaded() {
    try {
      await this.driver.wait(until.elementLocated(this.navHome), 5000);
      return true;
    } catch (e) {
      return false;
    }
  }

  async navigateTo(routeName) {
    const selectorMap = {
      home: this.navHome,
      farms: this.navFarms,
      sales: this.navSales,
      reminders: this.navReminders,
      scan: this.navScan,
      history: this.navHistory,
      profile: this.navProfile,
      settings: this.navSettings,
      directory: this.navDirectory
    };
    const sel = selectorMap[routeName.toLowerCase()];
    if (sel) {
      const el = await this.driver.findElement(sel);
      await el.click();
    }
  }
}

module.exports = DashboardPage;
