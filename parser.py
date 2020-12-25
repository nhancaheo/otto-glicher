if __name__ == "__main__":
    with open("./flanks_occ.txt", "r") as file:
        file_string = file.read()
    
    # parse string from file
    dict_p = dict(entry.split(": ") for entry in file_string.split("\n"))

    # transform entries to ints
    final_dict = dict((int(k), int(dict_p[k])) for k in dict_p)

    sum = 0
    for k, v in final_dict.items():
        sum += v
        if sum == 101:
            print("key for 10%:", k)
        if sum == 206:
            print("key for 20%:", k) # == 8739