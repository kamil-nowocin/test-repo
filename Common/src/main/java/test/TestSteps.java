/* (C) Kamil Nowocin (2025) | Tests */
package test;

import static org.assertj.core.api.Assertions.assertThat;

import io.qameta.allure.Step;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

@Slf4j
@AllArgsConstructor
public class TestSteps {

  private WebDriver driver;
  private WebDriverWait driverWait;

  @Step("Opening Google homepage")
  public TestSteps openGoogleHomePage() {
    driver.get("https://www.google.com");
    assertThat(driver.getTitle()).withFailMessage("Google homepage title should contain 'Google'")
        .contains("Google")
    return this;
  }

  @Step("Dismissing 'Skip Search Engine' prompt if present")
  public TestSteps dismissSearchEnginePromptIfPresent() {
    try {
      final var skipSearchEnginePrompt = driverWait.until(
          ExpectedConditions.elementToBeClickable(By.id("L2AGLb")));
      skipSearchEnginePrompt.click();
    } catch (Exception e) {
      log.info("Skip Search Engine prompt not present, continuing test.");
    }
    return this;
  }

  @Step("Performing search for {query}")
  public TestSteps performSearch(final String query) {
    final var searchBox = driver.findElement(By.name("q"));
    searchBox.sendKeys(query);
    searchBox.submit();
    return this;
  }

  @Step("Verifying search results are displayed")
  public TestSteps verifySearchResults() {
    final var results = driverWait.until(
        ExpectedConditions.visibilityOfAllElementsLocatedBy(By.cssSelector("h3")));
    assertThat(results.isEmpty()).withFailMessage("Search results should be displayed").isFalse();
    return this;
  }
}
