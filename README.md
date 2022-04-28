# ID616 OSC - Bash Script Assignment
## Linux User Enviroment Configuration and Backup service

|Author|Code|Last Update|
|:---|:---|---:|
|Aardhyn Lavender|laveat1|28/04/2022|

```bash
git clone https://github.com/AardhynLavender/OSC-Bash-Script-Assignment/
cd OSC-Bash-Scipt-Assignment
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

### Pre-requisites

### Execution

*From project root*

```bash
```
