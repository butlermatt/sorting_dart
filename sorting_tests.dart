#library('sorting_dart');

#import('dart:isolate');
#import('dart:math');

/** 
 * Generate list of random numbers.
 * [List] will be [size] elements in length.
 * Returned list will contain elements from 0 to [size]
 */
List<num> createList(int size) {
  var randGen = new Random();
  var retList = new List<num>(size);
  for(var i = 0; i < size; i++) {
    retList[i] = randGen.nextInt(size);
  }
  
  return retList;
}

void main() {
  // Change the value to passed to create a larger or smaller list
  // to be sorted.
  var myList = createList(1000);
  
  var stopWatch = new Stopwatch()..start();
  var listSort = new List<num>.from(myList);
  listSort.sort((a, b) => a - b);
  stopWatch.stop();
  print('List.Sort Time: ${stopWatch.elapsedInUs()}');
  stopWatch.reset();
  
  stopWatch.start();
  var bubblesortList = bubbleSort(myList);
  stopWatch.stop();
  print('Bubblesort Time: ${stopWatch.elapsedInUs()}');
  stopWatch.reset();

  stopWatch.start();
  var quicksortList = quicksort(myList);
  stopWatch.stop();
  print('Quicksort Time: ${stopWatch.elapsedInUs()}');
  stopWatch.reset();
  
  stopWatch.start();
  var insertList = insertSort(myList);
  stopWatch.stop();
  print('Insertion Sort Time: ${stopWatch.elapsedInUs()}');
  stopWatch.reset();
  
  stopWatch.start();
  var selectSortList = selectSort(myList);
  stopWatch.stop();
  print('Selection Sort Time: ${stopWatch.elapsedInUs()}');
  stopWatch.reset();
  
  stopWatch.start();
  var selectCocktailSortList = selectCocktailSort(myList);
  stopWatch.stop();
  print('Selection Cocktail Sort Time: ${stopWatch.elapsedInUs()}');
  stopWatch.reset();
  
  // Due to a weirdness with futures and isolates,
  // this test should be last.
  stopWatch.start();
  isolateQuicksort(myList).then((isolateSort) { 
    stopWatch.stop();
    print('Isolate Quicksort Time: ${stopWatch.elapsedInUs()}');
  });
  stopWatch.reset();
 
}

/**
 * Recursively call quicksort on [list] until ordered
 * list is returned. Uses a random pivot value 
 * (selected with: list[list.lenght ~/ 2])
 * See: http://en.wikipedia.org/wiki/Quicksort
 * This version is *very* memory unfriendly.
 */
List<num> quicksort(List<num> list) {

  if(list.length <= 1) return list;
  
  var pivotInd = list.length ~/ 2;
  var pivotVal = list[pivotInd];
  var lower = new List<num>();
  var upper = new List<num>();
  
  for(var i = 0; i < list.length; i++) {
    if(i == pivotInd) continue;
    if(list[i] <= pivotVal) {
      lower.add(list[i]);
    } else {
      upper.add(list[i]);
    }
  }
  
  // Could use .from() constructor and cascades to tighten this up.
  var ret = new List<num>();
  ret.addAll(quicksort(lower));
  ret.add(pivotVal);
  ret.addAll(quicksort(upper));
  return ret;
}

/**
 * Isolates cannot directly pass messages through parameters,
 * so this function wraps the [quicksort] function and uses
 * [port] to get the [ReceivePort].
 * Replies to [SendPort] with list sorted by [quicksort].
 */
void isolateWrapper() {
  port.receive((list, replyto) {
    var myList = quicksort(list);
    replyto.send(myList);
  });
}

/**
 * Returns a [Future] for the sorted [List]. This function performs
 * the normal first step of Quicksort selecting a random pivot value
 * and generates an upper and lower list. These lists are then passed
 * to a new Isolate which then calls standard [quicksort] function on
 * each. Esentually this simultaneously performs two quicksorts on
 * two different lists and then joins the results around the original
 * pivot point once both have completed.
 */
Future<List<num>> isolateQuicksort(List<num> list) {
  var completer = new Completer();
  var ret = new List<num>();
  
  var pivotInd = list.length ~/ 2;
  var pivotVal = list[pivotInd];
  
  var lower = new List<num>();
  var upper = new List<num>();
  
  for(var i = 0; i < list.length; i++) {
    if(i == pivotInd) continue;
    if(list[i] <= pivotVal) {
      lower.add(list[i]);
    } else {
      upper.add(list[i]);
    }
  }
  
  // Could merge these into Futures.wait but for visualization
  // this is a little easier.
  var lowFut = spawnFunction(isolateWrapper).call(lower);
  var hiFut = spawnFunction(isolateWrapper).call(upper);
  Futures.wait([lowFut, hiFut]).then((compLists) {
    var lowList;
    var hiList;
    
    // Can arrive in any order so check.
    if(compLists[0][0] < compLists[1][0]) {
      /* In rare cases, (particularly with small lists)
       * it is possible that the above will not work due
       * to the original pivot point being the upper
       * or lower extent of the list resulting in
       * one list being empty.
       * This is a known issue due to lack of checking.
       * These are proof of concept only not iron clad */
      //First list is smaller
      lowList = compLists[0];
      hiList = compLists[1];
    } else {
      lowList = compLists[1];
      hiList = compLists[0];
    }
    ret.addAll(lowList);
    ret.add(pivotVal);
    ret.addAll(hiList);
    completer.complete(ret);
  });
  
  return completer.future;
}

/**
 * Completes a Bubblesort on [list] returning the sorted [List]
 * This is only a single comparison and not bi-directional 
 * (Cocktail sort).
 * See: http://en.wikipedia.org/wiki/Bubblesort
 */
List<num> bubbleSort(List<num> list) {
  var retList = new List<num>.from(list);
  var tmp;
  var swapped = false;
  do {
    swapped = false;
    for(var i = 1; i < retList.length; i++) {
      if(retList[i - 1] > retList[i]) {
        tmp = retList[i - 1];
        retList[i - 1] = retList[i];
        retList[i] = tmp;
        swapped = true;
      }
    }
  } while(swapped);
  
  return retList;
}

/**
 * Completes Insertion Sort on [list], returning a new [List]
 * with the sorted elements.
 * See: http://en.wikipedia.org/wiki/Insertion_sort
 */
List<num> insertSort(List<num> list) {
  var retList = new List<num>();
  for(var el in list) {
    var inserted = false;
    if(retList.isEmpty()) {
      retList.add(el);
      continue;
    }
    for(var i = 0; i < retList.length; i++) {
      if(el < retList[i]) {
        retList.insertRange(i, 1, el);
        inserted = true;
        break;
      }
    }
    if(!inserted) {
      retList.add(el);
    }
  }
  
  return retList;
}


/**
 * Run a Selection Sort on [list]. Returns a new [List]
 * with the sorted elements.
 * See: http://en.wikipedia.org/wiki/Selection_sort
 */
List<num> selectSort(List<num> list) {
  var retList = new List<num>.from(list);
  var position = 0;
  var minInd = 0;
  
  do {
    for(var i = position; i < retList.length; i++) {
      if(i == minInd) continue;
      if(retList[i] < retList[minInd]) {
        minInd = i;
      }
    }
    
    if(position != minInd) {
      var tmp = retList[position];
      retList[position] = retList[minInd];
      retList[minInd] = tmp;
    }
    
    position += 1;
    minInd = position;
  } while(position < retList.length);
  
  return retList;
}

/**
 * selectCocktailSort is a variation of [selectSort] which simultaneously
 * finds and moves the largest element as well as lowest element.
 * Runs a Selection Cocktail Sort on [list] and returns a new sorted [List]
 * See: http://en.wikipedia.org/wiki/Selection_sort#Variants
 * (Also known as Bidirectional Selection Sort)
 */
List<num> selectCocktailSort(List<num> list) {
  var retList = new List<num>.from(list);
  var position = 0;
  var hiPosition = 0;
  var minInd = 0;
  var maxInd = 0;
  var tmp;
  
  do {
    for(var i = position; i < (retList.length - position); i++) {
      if(retList[i] < retList[minInd]) {
        minInd = i;
      }
      if(retList[i] > retList[maxInd]) {
        maxInd = i;   
      }
    }
    
    if(position != minInd) {
      tmp = retList[position];
      retList[position] = retList[minInd];
      retList[minInd] = tmp;
    } 
    
    hiPosition = (retList.length - 1) - position;
    if(hiPosition != maxInd) {
      if(maxInd == position) {
        // The largest variable is at the lower position.
        // It has been moved so we need to switch it here too.
        maxInd = minInd;
      }
      
      tmp = retList[hiPosition];
      retList[hiPosition] = retList[maxInd];
      retList[maxInd] = tmp;
    }
    
    position += 1;
    minInd = position;
    maxInd = position;
  } while(position <= (retList.length ~/ 2));
  
  return retList;
}
