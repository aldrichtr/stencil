---
title: README
url: https://github.com/aldrichtr/stencil
---

## Overview

stencil is a scaffolding system for powershell projects.

## Operations

- **Copy**

  Copy the contents of a directory or file from source to destination.  These are "static" files and directories.

- **New**

  Create a file or directory

- **Read**

  Ask for information.  Either from the user or a config file

- **Expand**

  Copy the content of a file to a new file, replacing tokens

- **Invoke**

  Run a script or command

## Walk-through

A stencil is a set of directories, files and scripts, with a manifest.

I think that a stencil manifest should be a series of steps that define each operation, in sequence.  I like the
idea of yaml like this:

```yaml
copy:
  source: .template/github
  target: ./.github
invoke: |
    Get-GitRepository | Set-Content .git-repo
expand:
  path: .template/build.T.ps1
  target: ./.build.ps1
  binding: build # the name of the variable that is bound to the template without the '$'
  safe: false
new:
  Path: # foreach child of Path, a Key is a directory, and the Value(s) are files in that directory
    source:
      classes:
      enum:
      private:
      public:
        - manifest.psd1
```

basically, the keys in each step are converted to a hash to be splatted to the appropriate command.

## Abstracting

I think it would be relatively easy to create a system where "chunks" of these atomic steps could be grouped
together and given a name. So for example, create a set of module folders, a manifest and a module file given a
module name and root folder.
