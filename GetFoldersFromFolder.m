function folders = GetFoldersFromFolder(root)

    folders = dir(root);
    folders = folders([folders.isdir]);
    folders = folders(3:end);
    folders = {folders.name};