# Commands

## Table of Contents
- [Commands](#commands)
  - [Brew Commands](#brew-commands)
    - [Publish](#publish)
    - [ImportTap](#importtap)
    - [CreateTap](#createtap)
    - [TapList](#taplist)
    - [Untap](#untap)
  - [Config Commands](#config-commands)
    - [SetListPath](#setlistpath)
    - [ShowListPath](#showlistpath)
    - [OpenListFolder](#openlistfolder)
    - [SetBuildType](#setbuildtype)
    - [ShowBuildType](#showbuildtype)


## Brew Commands
**Nnex** offers several subcommands under the `brew` namespace to manage Homebrew taps and releases.

### Publish
The `publish` command automates the process of creating a new release, uploading it to GitHub, and generating a Homebrew formula for distribution.

If you do not specify a version, notes/notes-file, or commit-messgage in the command, you will be prompted to do so after running the command.

**Usage:**
```bash
nnex brew publish [OPTIONS]
```

#### Options:
| Short | Long         | Description                                                                    
|------|--------------|--------------------------------------------------------------------------------
| `-p`   | `--path <value>`       | Path to the project directory where the release will be built. Defaults to the current directory. 
| `-v`   | `--version <value>`     | The version number to publish or version part to increment: major, minor, patch. 
| `-b`   | `--build-type <value>`  | The build type to set. Options: universal, release, debug.  Defaults to universal 
| `-n`   | `--notes <string>`       | Release notes content provided directly.                                         
| `-F`   | `--notes-file <value>`  | Path to a file containing release notes.                                         
| `-m`   | `--commit-message <string>` | The commit message when committing and pushing the tap to GitHub.            

#### Basic usage:
```bash
nnex brew publish
``` 

#### Specify Version:
When entering a version number, formats like `v1.0.0` and `1.0.0` will work.
```bash
nnex brew publish -v v1.0.0 
nnex brew publish --version v1.0.0
```

If a previous version already exists for your command-line tool, you may type `major`, `minor`, or `patch` to increment the corresponding number.

(If you had a 'v' in the previous version number, the incremented version will also include it)
```bash
nnex brew publish -v major  # Increment the major version (v1.1.3 -> v2.0.0)
nnex brew publish -v minor  # Increment the minor version (1.1.3 -> 1.2.0)
nnex brew publish -v patch  # Increment the patch version (1.0.1 -> 1.0.2)
```

#### Specify Release Notes 
Type your release notes directly in the command.

```bash
nnex brew publish -n "This release includes several bug fixes and improvements."
nnex brew publish --notes "This release includes several bug fixes and improvements."
```

Alternatively, you can provide a path to a file that contains your release notes. (Recommended if you want to include markdown and/or longer release notes)

```bash
nnex brew publish -F ./releaseNotes.md
nnex brew publish --notes-file ./releaseNotes.md
```

#### Specify Commit Message
This will be the message to commit the changes to the new formula.rb file created in your Homebrew tap folder. The new changes will then be pushed to GitHub.

```bash
nnex brew publish -m "Updated MyCoolTool.rb with version 2.0.0"
nnex brew publish --commit-message "Updated MyCoolTool.rb with version 2.0.0"
```

### Optional Arguments
By default, the `publish` command will run in the current directory, and it will build a universal binary to upload with your release.

You can change each of these values by inluding the options in the command.

#### Specify Path to Swift Package with executable target

```bash
nnex brew publish -p ~/Desktop/MyOtherProject
nnex brew publish --path ~/Desktop/MyOtherProject
```

#### Specify Binary Build Type

```bash
nnex brew publish -b arm64   # Apple Silicon 
nnex brew publish --build-type x86_64   # Intel
```

---

### ImportTap
Register an existing Homebrew tap from your local machine.

**Usage:**
```bash
nnex brew import-tap [OPTIONS]
```

#### Options:
| Short | Long  | Description                                                            
|------|-------|------------------------------------------------------------------------
| `-p`   | `--path <value>` | Local path to the folder that contains your Homebrew taps. If not provided, you will be prompted to enter it. 

#### Basic Usage

```bash
nnex brew import-tap
```

#### Specify Tap Folder Path

```bash 
nnex brew import-tap -p ~/HomebrewTaps/MyFavoriteTap
nnex brew import-tap --path ~/HomebrewTaps/MyFavoriteTap
```

---

### CreateTap
Registers a new Homebrew tap by creating a folder and initializing a local and remote git repository (GitHub only).

Homebrew tap folders must include the prefix `homebrew-'. However, when creating a new tap, you may simply input the name and **nnex** will automatically include the prefix.

**Usage:**
```bash
nnex brew create-tap [OPTIONS]
```

#### Options:
| Short | Long               | Description                                                       |
|------|--------------------|--------------------------------------------------------------------|
| `-n`   | `--name <string>`   | Name of the new Homebrew Tap.                                       |
| `-d`   | `--details <string>` | Description of the tap to include when uploading to GitHub.         |
|      | `--private`           | Set the repository visibility to private.                           |

                      

#### Basic Usage
```bash
nnex brew create-tap 
```

#### Specify Tap Name
```bash
nnex brew create-tap -n MyNewTap  # name will be changed to: homebrew-MyNewTap
nnex brew create-tap -name MyNewTap # name will be changed to: homebrew-MyNewTap
```

#### Specify Tap Details
```bash
nnex brew create-tap -d "This is going to be such a cool tap with a bunch of formulas"
nnex brew create-tap --details "This is going to be such a cool tap with a bunch of formulas"
```

#### Specify Private Visibility (not recommended)
```bash
nnex brew create-tap --private
```

---

### TapList
Displays the list of registered Homebrew taps, along with their local and remote paths.

**Usage:**
```bash
nnex brew tap-list
```

**Example Output:**
```bash
Found taps: 3
tap1
  formulas: 5
  localPath: /usr/local/Homebrew/Library/Taps/user/tap1
  remotePath: https://github.com/user/tap1
```

---

### Untap
Unregisters an existing Homebrew tap from **nnex**.

#### Choose from a list interactively
```bash
nnex brew untap mytap
```

#### Choose from a list interactively
```bash
nnex brew untap
```

---

## Config Commands
Manage configuration settings for **Nnex**.

### SetListPath
Sets the path where new Homebrew taps will be created.

**Usage:**
```bash
nnex config set-list-path [OPTIONS]
```

#### Options:
| Short | Long  | Description                                                  
|------|-------|--------------------------------------------------------------
| -p   | --path | The path where new Homebrew taps will be created.              

**Example:**
```bash
nnex config set-list-path -p /Users/username/TapList
```

---

### ShowListPath
Displays the current path to the folder where new taps will be created.

**Usage:**
```bash
nnex config show-list-path
```

**Example:**
```bash
nnex config show-list-path
```

---

### OpenListFolder
Opens the folder where taps are stored in Finder.

**Usage:**
```bash
nnex config open-list-folder
```

**Example:**
```bash
nnex config open-list-folder
```

---

### SetBuildType
Sets the default binary build type for publish commands.

**Usage:**
```bash 
nnex config set-build-type [buildType]
```

**Examples:**
```bash 
nnex config set-build-type release
```
```bash
nnex config set-build-type universal
```

---

### ShowBuildType
Displays the current default binary build type.

**Usage:**
```bash
nnex config show-build-type
```
