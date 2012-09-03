DSOS v0.01 Pre-Alpha
====

Repository For DSOS

DSOS is a Operating System That Completely Changes ComputerCraft.

DSOS is still pre-alpha, so don't expect anything awesome! (Exept CCIMG :D)

Install
=======

Take the BIOS.lua from "CC[CC Version]" and place it in [ComputerCraft Mod Directory]/lua

Next, Copy BIOS.lua from the BIOS directory and place it in the ComputerCraft Computer.

After that, Copy ALL of the .img files and place them in your computer.

Reboot the Computer.

There! You Installed DSOS!

API
===

  Mount


    mount.mount(image, point)

      Mounts an Image to Point. Can be accessed by Point:/

    mount.flush(point)

      Flushes data to disk

    mount.unmount(point)

      Unmounts the point, flushes.

    mount.getMounted()

      All of the mounted Images

    mount.mountDisk(side, point)

      Mounts a Disk on the selected side to the selected point

    mount.canMountDisk(side)

      Checks if a disk is formated

    mount.formatDisk(side)

      Correctly formats a disk

  FS


    fs.exists(path)

      returns true if the path exist, else false

    fs.list(path)

      returns all of the files and directories in a path

    fs.open(path, mode)

      opens the file with mode

        Modes:

          R Read

          W Write

      look at the CC wiki to figure out how to read and write files
