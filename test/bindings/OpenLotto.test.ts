import { ethers } from "ethers";
import { OpenLotto, LotteryItem } from '../../src/bindings/OpenLotto.ts';

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

  test("CreateLottery should throw InvalidName when Name is empty", async () => {
    let lottery = NewFilledLottery();
    lottery.Name = "";
    await expect(() => openlotto.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidName");
  })

  test("CreateLottery should throw InvalidRoundsConfiguration when Rounds is 0", async () => {
    let lottery = NewFilledLottery();
    lottery.Rounds = 0;
    await expect(() => openlotto.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidRoundsConfiguration");
  })

  test("CreateLottery should throw InvalidRoundsConfiguration when RoundBlocks is 0", async () => {
    let lottery = NewFilledLottery();
    lottery.RoundBlocks = 0;
    await expect(() => openlotto.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidRoundsConfiguration");
  })

  test("CreateLottery should throw InvalidDistributionPool when DistributionPoolShare sume more than 100", async () => {
    let lottery = NewFilledLottery();
    lottery.DistributionPoolShare[0] = BigInt('1000000000000000001');
    await expect(() => openlotto.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidDistributionPool");
  })

  test("CreateLottery should throw InvalidPrizePool when PrizePoolShare doesn't sume 100", async () => {
    let lottery = NewFilledLottery();
    lottery.PrizePoolShare[0] = BigInt('0');
    await expect(() => openlotto.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidPrizePool");
  })

  test("CreateLottery should throw InvalidOperator when Operator is invalid", async () => {
    let lottery = NewFilledLottery();
    lottery.Operator = '0x0000000000000000000000000000000000000000'
    await expect(() => openlotto.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidOperator");
  })

  test("CreateLottery should return incremental ids", async () => {
    let lottery = NewFilledLottery();
    let id = await openlotto.CreateLotteryAndWait(lottery);
 
    expect(await openlotto.CreateLotteryAndWait(lottery)).toEqual(id + 1);
    expect(await openlotto.CreateLotteryAndWait(lottery)).toEqual(id + 2);
    expect(await openlotto.CreateLotteryAndWait(lottery)).toEqual(id + 3);
  }, 30000)

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