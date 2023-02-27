#Creates a json file with all the projects ===> roles ===> principles (Example data.json attached)
import json
import subprocess
# Project IDs are stored in the list format
projects = []
# Getting the project list in json format
cmd = 'gcloud projects list --format=json'
data = subprocess.check_output(cmd, shell=True)
project_id = json.loads(data.decode())
# Debug to print the list of all the projects in the gcp account
print(project_id)
# Looping through the json file and appending the project IDs into the list
for id in project_id:
    projects.append(id['projectId'])
all_projects_roles_principles = [] # Storing all the projects with roles and principles as a list
project_to_users = {} # Dictionary to map project ID as key and user_role
final_out = {}
# Looping through all the projects to get the iam policies for a project in json format
for each_project in projects:
    ids = f"gcloud projects get-iam-policy {each_project} --format=json"
    bind = subprocess.check_output(ids, shell=True)
    iam_roles = json.loads(bind.decode())
    # Debug to print all the bindings list of members and the roles that are attached to the members
    print(iam_roles)
    role_to_principle_dict = {} # Dictionary to store role as key and principles(list) as value
    # Looping through the bindings for a specific roles and storing the emails in principles list
    for member in iam_roles['bindings']:
        principles_list = [] # List of all the principles for a specific role
        # Looping through all the members i.e., principles
        for principle in member['members']:
            # Organization roles are omitted here
            if "organization" in member['role']:
                pass
            # Emails will be appended to the principles list
            # Roles will be mapped to the principles list and stored in dictionary role_to_principle_dict
            else:
                principles_list.append(principle)
                role_to_principle_dict[member['role'].replace("roles/", "")] = principles_list
    # the role_to_principle_dict will be stored in project_to_users dictionary with project ID as key and role_to_principle_dict as value
    project_to_users[f'{each_project}'] = role_to_principle_dict
# Appending all the projects as a list with roles and principles
all_projects_roles_principles.append(project_to_users)
# Creating dictionary under user_roles as key and all_projects_roles_principles as key
final_out['user_roles'] = all_projects_roles_principles
# Debug the final dictionary which has all the projects, roles and principles
print(final_out)
# writing the above as a json file to data.json
with open('data.json', 'w') as f:
    json.dump(final_out, f, indent=1)
