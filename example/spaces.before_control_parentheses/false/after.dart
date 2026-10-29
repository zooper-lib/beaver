void example() {
  if(ready) start();
  for(var i = 0; i < 3; i++) tick();
  while(running) step();
}
