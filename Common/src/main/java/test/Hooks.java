/* (C) Kamil Nowocin (2025) | Tests */
package test;

import static lombok.AccessLevel.PRIVATE;
import static lombok.AccessLevel.PUBLIC;
import static org.openqa.selenium.OutputType.BYTES;
import static org.testng.ITestResult.FAILURE;
import io.github.bonigarcia.wdm.WebDriverManager;
import io.qameta.allure.Allure;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.Objects;
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.FileUtils;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.testng.ITestResult;
import org.testng.annotations.AfterClass;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeClass;

@Slf4j
public class Hooks {

  @Getter(value = PUBLIC)
  @Setter(value = PRIVATE)
  private WebDriver driver;
  @Getter(value = PUBLIC)
  @Setter(value = PRIVATE)
  private WebDriverWait driverWait;

  @BeforeClass
  public void setup() {
    WebDriverManager.chromedriver().setup();
    final var options = new ChromeOptions();
    options.addArguments("---disable-search-engine-choice-screen");
    options.addArguments("--start-maximized");
    options.addArguments("--lang=en");
    options.addArguments("--headless");
    options.addArguments("--disable-gpu");
    options.addArguments("--no-sandbox");
    options.addArguments("--disable-dev-shm-usage");
    options.addArguments("--incognito");

    this.driver = new ChromeDriver(options);
    this.driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(10));
    this.driverWait = new WebDriverWait(this.driver, Duration.ofSeconds(10));
  }

  @AfterMethod
  public void captureScreenshotIfTestFails(final ITestResult result) {
    if (FAILURE == result.getStatus()) {
      takeScreenshot();
    }
  }

  @AfterClass
  public void tearDown() {
    if (Objects.nonNull(this.driver)) {
      driver.quit();
    }
  }

  public void moveAllureResultsContent(final String moduleName) {
    final var source = createAllureResultsPath(moduleName, "build").toFile();
    final var destination = createAllureResultsPath("build").toFile();
    try {
      FileUtils.copyDirectory(source, destination);
      log.info("Przeniesiono zawartość katalogu Allure z {} do {}", source.getPath(),
          destination.getPath());
      FileUtils.cleanDirectory(source);
    } catch (IOException e) {
      log.info("Wystąpił błąd podczas przenoszenia zawartości katalogu Allure: {}", e.getMessage());
    }
  }

  private void takeScreenshot() {
    Allure.addAttachment("Screenshot", "image/jpg",
        new ByteArrayInputStream(((TakesScreenshot) this.driver).getScreenshotAs(BYTES)), "jpg");
  }

  private Path createAllureResultsPath(final String... paths) {
    return Paths.get(Path.of("").toAbsolutePath().toString(), Paths.get("", paths).toString(),
        "allure-results");
  }
}
