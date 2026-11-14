# Practice table for the test recording

Owner: Pranav. This is the hand-counted warm-up from the phase guide. Show it on screen during the 10-second microphone test.

In the middle row, an instruction fetch and a data write arrive at the same time. With two separate ports, both finish in the same turn. With one shared port, the write goes first and the fetch waits for the next turn.

| Requests | Two separate ports | One shared port |
| --- | --- | --- |
| Fetch | Turn 1 | Turn 1 |
| Fetch and write | Turn 2 for both | Turn 2 write, turn 3 fetch |
| Fetch | Turn 3 | Turn 4 |

Check: both sides make 4 transfers. The split paths take 3 turns and the shared port takes 4. The real demo trace has one more overlap, so it gives 5 vs 7 (see [the baseline](../baseline.md)).

Test line to say while recording:

> "One connection handles the next instruction. A different connection handles the data write. Here they run on the same clock edge."
