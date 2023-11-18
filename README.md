# ID616 OSC - Bash Script Assignment
## Linux User Enviroment Configuration and Backup Service

|Author|Code|Last Update|
|:---|:---|---:|
|Aardhyn Lavender|laveat1|03/05/2022|

```bash
git clone https://github.com/AardhynLavender/OSC-Bash-Script-Assignment/
cd Bash-Script-Assignment
```

## Task One - Creating a User Environment

### Summary

The purpose of the program is to create user enviroments based on provided data. This involves home directories, appropriate user configuration, aliases, and shared directories ( including links ). 

A summary of the enviroment configuration process is displayed in a table, and detailed infomation is logged to a `.log` file for further inspection after the fact.

### Pre-requisites

- Acccess to either a local file containing user data of the required schema, or a a url pointing to the aforementioned.
- Access to a user with sudo permissions or root ( the script will ask )

### File Schema

The parsed file must conform to the following schema, using semicolons as field delimiters and newlines to seperate entries

```plaintext
e-mail;birth date;groups;sharedFolder
```

The first line in the file must store the above line for schema validation.

### Execution

*From project root*

```bash
./task1/createUserEnviroment.sh
```

*Run without arguments for guided execution*

With arguments, specify a local file as the first argument

```bash
./task1/createUserEnviroment.sh data/users.csv
```

Alternatively, pass the `-r` flag and specify a url

```bash
./task1/createUserEnviroment.sh -r http://10.0.0.24/users.csv
```

## Task Two - Backup Script

### Summary

The purpose of the program is to compress a given directory and copy it securely to a specified remote server. Like `task one` the script displays the compression and transfer process by means of standard output and detailed log file.

### Pre-requisites

- A directory to compress
- A remote server including:
  - Access to a user with write permissons to at least one directory ( most likely you can use the `home directory` of the provided user )
  - A port that permits `ssh`--usually 22--or some special `shh tunneling` setup.

### Execution

*From project root*

```bash
./task2/backupScript.sh
```

*Run without arguments for guided execution*

With arguments, specify a local file as the first--and only--argument

```bash
./task2/backupScript.sh ./testDirectory
```

## Assignment Submission

Self assesment is provided in project root.

### Groups

```bash
cat /etc/groups
```

![image](https://user-images.githubusercontent.com/83677410/166403900-3117f4c0-f7a6-4ac4-b503-a7d0d387e6b0.png)

staff was hiding further up...

![image](https://user-images.githubusercontent.com/83677410/166403923-9b9c3d7b-207c-46f2-96f0-e428c47e6f10.png)

### Passwords

```bash
cat /etc/passwd/
```

![image](https://user-images.githubusercontent.com/83677410/166403979-6da93854-2d86-4feb-b8fc-831bc0407083.png)

### Secure Copy Execution Output

![image](https://user-images.githubusercontent.com/83677410/166404517-5a0d9f85-efcc-47dd-92c7-cd15aca402df.png)
