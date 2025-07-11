# Fulpstation Codebase

## Contribute to TG or Fulp?

As we are a TG downstream, any PR that they merge will eventually trickle down to us. We highly encourage contributors to PR to TG rather than Fulp since it will help us both in the long run.
- <https://github.com/tgstation/tgstation>

This policy is a very important thing to know before contributing to Fulpstation. We rebased to rid ourselves of the old grudgecode, we do not wish to re-become it.

NOTE: If you plan on contributing to Fulpstation, you may want to read the guide located here:
- <https://wiki.fulp.gg/en/GuideToContributing>

## Modular Code/Modularity

Modular, as we use it, is described as "Doesn't touch Core TG files/folders".

### What is a TG file and why does it matter?

- A TG file is a file that we share with our upstream, TGstation. Every time we update, all our files get updated to whatever TG has them set to.
- To counter this, we have our a fulp_modules folder, containing all the fulp files.
- There is one exception: our TGUI files. These are placed in the same folder as TG's. It's there because of some dumb tgui stuff who cares no one really knows, it just does. Ok?

### What is a TG edit?

- A TG edit is when Fulp code is inserted into a TG core file/folder.
- Obvious examples of this would be our maps and tgui files, but these are also used for changes that can't work as overrides.

### What are Overrides?

- Since our '.dm' files are included last in `tgstation.dme`, any datums/procs declared (or even *redeclared*) within them will take precedence over the versions found in '/code'.
- This is very useful since it allows us to change TG code without making a direct TG edit.
- DO NOTE: It's best to use overrides sparingly and with clear documentation and/or comments. They have the potential to cause a lot of confusion and bugs during TGUs if we inherit changes from TG that affect things we've overriden.

## Fulp Modules

### What is Fulp Modules?

This file contains nearly all of the code exclusive to Fulpstation.

Due to how maintaining a downstream codebase works, we must frequently make sure our code is as modular as possible. This is the best way to keep us up-to-date without requiring days worth of effort for every update.

We are incredibly strict in modularity, and Pull Requests can (and will) be quickly denied and closed if they are unable to be modular. Exceptions are granted to this, such as if we are already touching said file, as numbers of lines edited is irrelevant once there's at least one line changed.

## Readme & TG edits

Any Pull Request that touches a TG file, or uses TG sprites/sounds, MUST include a readme.MD page in its folder to explain such.
Additionally, edits to TG files MUST be documented in tg_edits.md - This is because it is the primary file Contributors will look at to ensure all Fulp code persists through TGUs.

![image](https://i.imgur.com/4p3iTRx.jpg)

# Workflows

Since we handle workflows ourselves and TG hands us their workflows, you should disable your fork's workflows (**except CI Suite and Generate Documentation**) to not get flooded with emails. To do this, go onto your fork of the repository, go to the Actions tab, and for each workflow:

1) Click the ... (ellipses) at the top right.
2) Press "disable workflow".

It should end up looking like this:

![image](https://i.imgur.com/J8BaqtN.png)

Our repo and your fork have different workflows: yours won't affect ours. This will, however, prevent you from getting flooded with failed workflow notifiction emails. While all of this isn't required, it is recommended.

## Outside of Fulp modules

### Defines

Defines need to be ticked (i.e. listed in the .dme) before the files where they're used. This includes helpers, symbolic constants, etc. If we were to keep our defines inside of the `fulp_modules` folder, they would be ticked before *our* files, but *after* TG's files. This is a problem if we ever want to make use of them in a TG edit or files placed (by necessity) outside of `fulp_modules`.

For this reason, all our defines are placed in a subfolder called `fulp_defines` inside of TG's `code/__DEFINES` folder. This way, they are ticked immediately after TG's defines.

### Maps

Maps are kept outside of `fulp_modules` for two reasons.

 - In the case of stations and shuttles, the code that loads maps requires them to adhere to a certain file structure. This, in turn, forces us to keep their .json file and .dmm files within the `_maps` folder.

 - In the case of ruins and other non-station maps, we keep them inside the `_maps/fulp_maps` folder so that the UpdatePaths tool can find and update them without needing to modify the script.

### TGUI

Due to how TG handles TGUI, there is currently no known way to make this hosted in the Fulp modules folder. They are therefore put in TG's TGUI folder instead. While this is an annoyance, we don't have any better alternative for now, so you can ignore it lacking modularity.

## TGU

A TGU (TG Update) is when a contributor updates our repository to the latest version of TG code (<https://github.com/tgstation/tgstation/>).
We do NOT have a mirror bot, so things must be manually done with GitBash (<https://gitforwindows.org/>) by setting tgstation/tgstation as your remote upstream. If you do not know how, you can ask in the Discord for help.

When a contributor does a TGU, there are a few things they must ensure:
1) No Fulpstation edits or files are being deleted. You can use our `tg_edits.md` file to help guide yourself through this— it lists all of our edits.
2) The `tgstation.dme` file isn't commenting out any Fulp files and is fully up-to-date.

Ideally, a TGU should occur at least every two months. This allows TGUs to remain relatively manageable and unintimidating .
