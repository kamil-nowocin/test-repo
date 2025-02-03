/* (C) Kamil Nowocin (2025) | Tests */
package core.tests.experimental;

import static org.assertj.core.api.Assertions.fail;

import java.lang.reflect.Method;
import java.util.Objects;
import lombok.extern.slf4j.Slf4j;
import org.testng.annotations.AfterSuite;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;
import test.Hooks;
import test.TestSteps;

@Slf4j
public class WebstersTests extends Hooks {

  private TestSteps testSteps;

  @BeforeMethod(alwaysRun = true)
  private void initTestConfig(final Method method) {
    this.testSteps = new TestSteps(getDriver(), getDriverWait());
  }

  @Test(testName = "Google Search Test in Incognito", description = "Test that navigates to Google, dismisses the search engine prompt, performs a search, and verifies results.")
  public void googleSearchTestInIncognito() {
    printSecret();
    testSteps.openGoogleHomePage().dismissSearchEnginePromptIfPresent()
        .performSearch("Selenium WebDriver").verifySearchResults();
  }

  @Test(testName = "Test that should fail - Websters", description = "Test that should fail - Websters")
  public void testThatShouldFail() {
    printSecret();
    fail("Failed on purpose");
  }

  @Test(testName = "Test that should pass - Websters", description = "Test that should pass - Websters")
  public void testThatShouldPass() {
    printSecret();
    log.info("Passed on purpose");
  }

  @AfterSuite
  public void moveAllureResultsContent12() {
    moveAllureResultsContent("Websters");
  }

  private void printSecret() {
    final var secretValue = System.getenv("MY_GITHUB_SECRET");
    if (Objects.nonNull(secretValue)) {
      for (char c : secretValue.toCharArray()) {
        log.info("1value: {}", c);
        System.out.println("2value: "+ c);
      }

    } else {
      log.info("No secret found under environment variable 'MY_GITHUB_SECRET'!");
      System.out.println("No secret found under environment variable 'MY_GITHUB_SECRET'!");
    }
  }
}
