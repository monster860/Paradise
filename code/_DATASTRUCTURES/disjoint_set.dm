/datum/disjoint_set
	var/list/parents = list()
	
/datum/disjoint_set/New(var/len)
	parents.len = len
	for(var/I in 1 to len)
		parents[I] = I

/datum/disjoint_set/proc/find(index)
	if(index < 1 || index > parents.len)
		return -1
	if(parents[index] != index)
		parents[index] = find(parents[index])
	return parents[index]

/datum/disjoint_set/proc/union(x, y)
	var/x_root = find(x)
	var/y_root = find(y)
	parents[x_root] = y_root