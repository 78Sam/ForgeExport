import requests
from random import choice, shuffle, randint, random
from time import sleep


pages: dict[str, str] = {
    "login": "http://172.18.0.2/wp-login.php",
    "wp-admin": "http://172.18.0.2/wp-admin/",

    # Content Management
    "posts": "http://172.18.0.2/wp-admin/edit.php",
    "edit-post": "http://172.18.0.2/wp-admin/post.php?post=10&action=edit",
    "add-post": "http://172.18.0.2/wp-admin/post-new.php",
    
    "pages": "http://172.18.0.2/wp-admin/edit.php?post_type=page",
    "edit-page": "http://172.18.0.2/wp-admin/post.php?post=29&action=edit",
    "add-page": "http://172.18.0.2/wp-admin/post-new.php?post_type=page",

    # Media
    "media": "http://172.18.0.2/wp-admin/upload.php",
    "upload-media": "http://172.18.0.2/wp-admin/media-new.php",

    # Comments
    "comments": "http://172.18.0.2/wp-admin/edit-comments.php",

    # Plugins
    "plugins": "http://172.18.0.2/wp-admin/plugins.php",
    "add-plugin": "http://172.18.0.2/wp-admin/plugin-install.php",

    # Themes & Customization
    "themes": "http://172.18.0.2/wp-admin/themes.php",
    "customizer": "http://172.18.0.2/wp-admin/customize.php",

    # User & Account Management
    "accounts": "http://172.18.0.2/wp-admin/users.php",
    "edit-profile": "http://172.18.0.2/wp-admin/profile.php",
    "add-user": "http://172.18.0.2/wp-admin/user-new.php",

    # Site Settings
    "general-settings": "http://172.18.0.2/wp-admin/options-general.php",
    "reading-settings": "http://172.18.0.2/wp-admin/options-reading.php",
    "writing-settings": "http://172.18.0.2/wp-admin/options-writing.php",
    "discussion-settings": "http://172.18.0.2/wp-admin/options-discussion.php",
    "permalinks": "http://172.18.0.2/wp-admin/options-permalink.php"
}

access: dict = {
    4: [  # Administrator - Only lists admin-exclusive access (inherits all below)
        "plugins", "add-plugin", "themes", "customizer",
        "accounts", "add-user", "general-settings",
        "reading-settings", "writing-settings", "discussion-settings", "permalinks",
    ],
    3: [  # Editor - Only lists editor-exclusive access (inherits all below)
        "pages", "edit-page", "add-page", "comments"
    ],
    2: [  # Author - Only lists author-exclusive access (inherits all below)
        "posts", "edit-post", "add-post", "media", "upload-media"
    ],
    1: [  # Contributor - Can only write drafts (inherits all below)
        "add-post"
    ],
    0: [  # Subscriber - Can only access their profile
        "wp-admin", "edit-profile"
    ]
}

accounts: dict[str] = {
    "root": {
        "name": "root",
        "log": "root",
        "pwd": "root",
        "type": "administrator",
        "level": 4,
    },
    "kathy": {
        "name": "kathy",
        "log": "kathy",
        "pwd": "kathyspassword",
        "type": "editor",
        "level": 3
    },
    "steve": {
        "name": "steve",
        "log": "steve",
        "pwd": "steveiscool",
        "type": "subscriber",
        "level": 0
    },
}

with requests.Session() as s:

    account = accounts[choice(list(accounts.keys()))]

    # Admin flow

    username = account["log"]
    password = account["pwd"]

    headers1 = {
        "Cookie": "wordpress_test_cookie=WP Cookie check"
    }

    datas = { 
        "log": username,
        "pwd": password,
        "wp-submit": "Log In", 
        "redirect_to": pages["wp-admin"],
        "testcookie":"1"  
    }

    try:

        s.post(pages["login"], headers=headers1, data=datas)

        s.get(pages["wp-admin"])

        route = []
        for access_num in range(0, account["level"]+1):
            for page in access[access_num]:
                route.append(page)

        shuffle(route)
        for page in route:
            resp = s.get(pages[page])
            # print(f"Access of {page} for {account['name']} is {resp.status_code}")
            sleep(randint(2, 4) + random())

    except Exception as e:
        print(f"Admin req failed to get page as {account}")

sleep(2)