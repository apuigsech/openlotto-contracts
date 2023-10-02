import { ethers, Interface, keccak256 } from "ethers";

import { OpenLotto, LotteryItem } from '../../src/bindings/OpenLotto.ts';
import LotteryDatabaseArtifact from "../../out/LotteryDatabase.sol/LotteryDatabase.abi.json"
import TicketDatabaseArtifact from "../../out/TicketDatabase.sol/TicketDatabase.abi.json"
import DatabaseArtifact from "../../out/Database.sol/Database.json"

const provider = new ethers.JsonRpcProvider("http://localhost:8545");
const mnemonic = "test test test test test test test test test test test junk";
const path = "m/44'/60'/0'/0/1";

const wallet = ethers.HDNodeWallet.fromMnemonic(ethers.Mnemonic.fromPhrase(mnemonic), path);
const signer = wallet.connect(provider);

const openLottoAddress = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0';
const dummyOperator = '0x8464135c8F25Da09e49BC8782676a84730C318bC';

describe("OpenLotto", () => {
  let openlotto;

  beforeAll(async () => {
    openlotto = new OpenLotto(openLottoAddress, signer);
  });

  beforeEach(async () => {

  });

  test("CreateLottery", async () => {
    let lottery;
    let id;
 
    lottery = NewFilledLottery();
    id = await openlotto.CreateLotteryAndWait(lottery);
    expect(id).toEqual(2);
    
    // openlotto.contract.CreateLottery(lottery).then(tx => {
    //   console.log(tx);
    //   tx.wait().then(receipt => {
    //     let ids = receipt.logs.map((log) => {
    //       let event = openlotto.lottery_db.interface.parseLog(log);
    //       if (
    //         event.name == 'CreatedItem' &&
    //         event.args[0] == 'Lottery'
    //       ) {
    //         return event.args[1]
    //       }
    //     })
    //     console.log(ids);        
  })

  function NewFilledLottery(): LotteryItem {
    let lottery = openlotto.NewEmptyLottery();
    lottery.Name = 'dummy';
    lottery.InitBlock = BigInt('10');
    lottery.Rounds = 10;
    lottery.RoundBlocks = 100;
    lottery.PrizePoolShare[0] = BigInt('1000000000000000000');
    lottery.Operator = dummyOperator;
    return lottery;
  }

});