import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wanmac/models/wallet_transaction_model.dart';

double _scale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

class ActivityTile extends StatelessWidget {
  final WalletTransactionModel transaction;

  const ActivityTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final amountText =
        '${transaction.isCredit ? '+' : '-'}₦${NumberFormat('#,##0').format(transaction.amount)}';

    final amountColor = transaction.isCredit ? Colors.green : Colors.red;

    final formattedDate = transaction.createdAt != null
        ? DateFormat(
            'dd MMM yyyy, h:mm a',
          ).format(transaction.createdAt!.toLocal())
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: r(12)),
      padding: EdgeInsets.all(r(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r(14)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: r(22),
            backgroundColor: transaction.isCredit
                ? Colors.green.withOpacity(0.12)
                : Colors.red.withOpacity(0.12),
            child: Icon(
              transaction.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: amountColor,
              size: r(20),
            ),
          ),
          SizedBox(width: r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: r(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (transaction.message.isNotEmpty) ...[
                  SizedBox(height: r(4)),
                  Text(
                    transaction.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(12),
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (formattedDate.isNotEmpty) ...[
                  SizedBox(height: r(6)),
                  Text(
                    formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(11),
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: r(8)),
          Text(
            amountText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: r(14),
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
