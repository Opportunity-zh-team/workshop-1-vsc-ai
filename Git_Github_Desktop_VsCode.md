# Git, GitHub Desktop and Visual Studio Code Setup

This manual explains how to install Visual Studio Code, GitHub Desktop, and Git for Windows. It also explains how to create or clone a repository and open it in Visual Studio Code.

## 1. Install Visual Studio Code

1. Open a web browser.
2. Go to the official Visual Studio Code website:

   **<https://code.visualstudio.com/>**

3. Download the Windows installer.
4. Start the downloaded installer.
5. Follow the installation instructions.
6. Accept the license agreement.
7. Keep the recommended installation options unless instructed otherwise.
8. Complete the installation.
9. Start Visual Studio Code.

<!-- Add additional information or screenshots here. -->

## 2. Install GitHub Desktop

1. Open a web browser.
2. Go to the official GitHub Desktop website (Download for Windows 64 bit):

   **<https://desktop.github.com/download/>**

3. Download GitHub Desktop for Windows.
4. Start the downloaded installer.
5. Follow the installation instructions.
6. Start GitHub Desktop.
7. Sign in with your GitHub account.

<!-- Add additional information or screenshots here. -->

## 3. Create a New Repository

1. Open GitHub Desktop.
2. Select **File** > **New repository**.
3. Enter a name for the repository.
4. Select the local folder where the repository should be stored.
5. Optionally add a description.
6. Choose whether the repository should be public or private.
7. Click **Create repository**.
8. If required, click **Publish repository** to upload it to GitHub.

<!-- Add additional information or screenshots here. -->

## 4. Clone an Existing Repository

1. Open GitHub Desktop.
2. Select **File** > **Clone repository**.
3. Select the **GitHub.com** tab, or enter the repository URL manually.
4. Select the repository to clone.
5. Choose the local folder where it should be stored.
6. Click **Clone**.
7. Wait until the repository has been downloaded.

<!-- Add additional information or screenshots here. -->

## 5. Open the Repository in Visual Studio Code

1. Open GitHub Desktop.
2. Select the repository.
3. Click **Open in Visual Studio Code**.

   Alternatively:

4. Open Visual Studio Code.
5. Select **File** > **Open Folder**.
6. Select the local repository folder.
7. Click **Select Folder**.
8. The repository is now open in Visual Studio Code.

<!-- Add additional information or screenshots here. -->

## 6. Install Git for Windows

When Visual Studio Code prompts you to install Git, install Git for Windows.

1. Press prompt Install Git button. If not working try this Link directly:

   **[Git - Install for Windows](https://git-scm.com/install/windows)**

2. Find the section **Standalone Installer**.
3. Select the following installer:

   **[Git for Windows/x64 Setup](https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-2.55.0.5-64-bit.exe)**

4. Download the installer.
5. Start the downloaded installer.
6. Follow the installation instructions.
7. Keep the recommended options unless instructed otherwise.
8. Complete the installation.
9. Restart Visual Studio Code if necessary.
10. Confirm that Git is available in Visual Studio Code.

#### Interesting detail: With git installed, you get git bash, a linux terminal emulator, that lets u use Unix commands in Powershell 


<!-- Add additional information or screenshots here. -->

## 7. Verify the Installation

1. Open Visual Studio Code.
2. Open the repository folder.
3. Select the **Source Control** icon on the left.
4. Confirm that Git is detected.
5. Open the integrated terminal using **Terminal** > **New Terminal**.
6. Enter the following command:

   ```powershell
   git --version
   ```
7. Confirm that a Git version is displayed.   

## 8. Make Changes and Commit Them

1. Edit or create a file in Visual Studio Code.
2. Save the file.
3. Open the Source Control view.
4. Review the changed files.
5. Enter a commit message.
6. Click Commit.
7. Open GitHub Desktop.
8. Review the committed changes.
9. Click Push origin to upload the changes to GitHub.
<!-- Add additional information or screenshots here. -->

9. Additional Notes
<!-- Add additional instructions, screenshots, links, or troubleshooting information here. -->

* Document written by [Gaudenz Raiber](mailto:gaudenz.raiber@zuerich.ch), Date 03/09/2026 [de-DE]