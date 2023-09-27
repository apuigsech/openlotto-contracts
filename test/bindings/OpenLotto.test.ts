import { ethers } from "ethers";
import { OpenLotto, LotteryItem } from '../../src/bindings/OpenLotto.ts';

const provider = new ethers.JsonRpcProvider("http://localhost:8545");
const mnemonic = "test test test test test test test test test test test junk";
const path = "m/44'/60'/0'/0/1";

const wallet =  ethers.HDNodeWallet.fromMnemonic(ethers.Mnemonic.fromPhrase(mnemonic));
const signer = wallet.connect(provider);

const openLottoAddress = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0';
const dummyOperator = '0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6';

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
    // id = await openlotto.CreateLotteryAndWait(lottery);
    // expect(id).toEqual(1);


  });


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